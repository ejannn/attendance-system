from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

from app.core.database import get_db
from app.models import User
from app.schemas import RegisterRequest
from app.core.security import create_access_token, get_current_user
from app.dependencies import require_permission
from app.permissions import Permissions
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["Users"])


# ── Register ──────────────────────────────────────────────────────────────────

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register_user(
    body: RegisterRequest,
    db: Session = Depends(get_db)
):
    return UserService.register(db, body.username, body.full_name, body.password)


# ── Login ─────────────────────────────────────────────────────────────────────

@router.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = UserService.authenticate(db, form_data.username, form_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(
        user=user,
        expires_delta=timedelta(minutes=30)
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role.name,
        "permissions": [p.name for p in user.role.permissions]
    }


# ── Get current user info ─────────────────────────────────────────────────────

@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "username": current_user.username,
        "full_name": current_user.full_name,
        "role": current_user.role.name,                              
        "permissions": [p.name for p in current_user.role.permissions]  
    }


@router.post("/admin/create-user", status_code=status.HTTP_201_CREATED)
def admin_create_user(
    body: RegisterRequest,
    role_name: str = "student",
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    """Admin-only route to create a user with a specific role."""
    return UserService.admin_create_user(db, body.username, body.full_name, body.password, role_name)


# ── Admin: list all users ──────────────────────────────────────────────────────

@router.get("/all")
def get_all_users(
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    users = UserService.get_all(db)
    return [
        {
            "id": u.id,
            "username": u.username,
            "full_name": u.full_name,
            "role": u.role.name
        }
        for u in users
    ]


# ── Admin: change a user's role ────────────────────────────────────────────────

@router.patch("/admin/change-role/{user_id}")
def change_user_role(
    user_id: int,
    role_name: str,
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    return UserService.change_role(db, user_id, current_user, role_name)