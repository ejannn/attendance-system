from fastapi import Depends, HTTPException, status

from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from datetime import datetime, timedelta
import hashlib
import os
import hmac

from .database import get_db
from .models import User

# ================= JWT SETTINGS =================
SECRET_KEY = "your_secret_key_here_change_this"
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
    salt_hex, hash_hex = hashed_password.split(":")
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
def create_access_token(data: dict, expires_delta: timedelta | None = None):
    """
    Creates a JWT token. The `data` dict can include roles, e.g.:
    {"sub": username, "role": "admin"}
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# ================= CURRENT USER =================
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    """
    Returns the current logged-in user object.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        role: str = payload.get("role")  # optional, from token
        if not username:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    user = db.query(User).filter(User.username == username).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    return user

# ================= ROLE-BASED AUTH =================
def require_role(required_role: str):
    """
    Dependency to protect routes by role.
    Usage:
        @app.get("/admin")
        def admin_route(current_user: User = Depends(require_role("admin"))):
            return {"msg": "Welcome admin!"}
    """
    def role_checker(current_user: User = Depends(get_current_user)):
        if current_user.role != required_role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to access this resource"
            )
        return current_user
    return role_checker




def require_admin(current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(
            status_code=403,
            detail="Admin access required"
        )
    return current_user
