from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

from ..database import get_db
from ..models import User
from ..auth import get_current_user, hash_password, verify_password, create_access_token, require_role

router = APIRouter(prefix="/users", tags=["Users"])

# -------------------
# REGISTER USER
# -------------------
@router.post("/register")
def register_user(
    username: str,
    password: str,
    role: str = "user",  # default role
    db: Session = Depends(get_db)
):
    existing_user = db.query(User).filter(User.username == username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    hashed = hash_password(password)
    user = User(
        username=username,
        password=hashed,
        role=role
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"msg": f"User '{username}' created with role '{role}'"}

# -------------------
# LOGIN USER
# -------------------
@router.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )

    # Include role in JWT
    access_token = create_access_token(
        data={"sub": user.username, "role": user.role},
        expires_delta=timedelta(minutes=30)
    )

    return {"access_token": access_token, "token_type": "bearer"}

# -------------------
# GET CURRENT USER INFO
# -------------------
@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    """
    Returns the current logged-in user info.
    By default, anyone with 'user' role or higher can access.
    """
    return {
        "id": current_user.id,
        "username": current_user.username,
        "role": current_user.role
    }

# -------------------
# ADMIN ONLY EXAMPLE
# -------------------
@router.get("/admin-dashboard")
def admin_dashboard(current_user: User = Depends(require_role("admin"))):
    """
    Only accessible by admin users.
    """
    return {"msg": f"Hello {current_user.username}, you are an admin!"}
