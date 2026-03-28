from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from datetime import datetime, timedelta
import hashlib
import os
import hmac

from app.core.database import get_db
from app.models import User

# ================= JWT SETTINGS =================
SECRET_KEY = os.getenv("SECRET_KEY", "change-this-in-production")  # ← from env
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/users/login")


# ================= PASSWORD HASHING =================
def hash_password(password: str) -> str:
    salt = os.urandom(16)
    pwd_hash = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode(),
        salt,
        100_000
    )
    return salt.hex() + ":" + pwd_hash.hex()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        salt_hex, hash_hex = hashed_password.split(":")
    except ValueError:
        return False  # ← guard against malformed hash

    salt = bytes.fromhex(salt_hex)
    expected_hash = bytes.fromhex(hash_hex)

    pwd_hash = hashlib.pbkdf2_hmac(
        "sha256",
        plain_password.encode(),
        salt,
        100_000
    )

    return hmac.compare_digest(pwd_hash, expected_hash)


# ================= TOKEN =================
def create_access_token(user: User, expires_delta: timedelta | None = None) -> str:
    """
    Creates a JWT token with permissions embedded.
    Permissions are read once at login — no DB hit on every request.
    """
    permissions = [p.name for p in user.role.permissions]  # ← embed permissions

    payload = {
        "sub": user.username,
        "user_id": user.id,
        "role": user.role.name,
        "permissions": permissions,  # ← key addition
        "exp": datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    }

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# ================= CURRENT USER =================
class TokenData:
    """Holds the decoded token payload — avoids repeated DB hits."""
    def __init__(self, payload: dict):
        self.username: str = payload.get("sub")
        self.user_id: int = payload.get("user_id")
        self.role: str = payload.get("role")
        self.permissions: set[str] = set(payload.get("permissions", []))


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Decodes the JWT and returns the User object.
    Permissions are already in the token — no extra DB query needed for auth checks.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        token_data = TokenData(payload)

        if not token_data.username:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.username == token_data.username).first()
    if not user:
        raise credentials_exception

    # ← Attach token permissions to the user object so require_permission()
    #   can read them without another DB query
    user._token_permissions = token_data.permissions

    return user
