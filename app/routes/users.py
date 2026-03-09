from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

from ..database import get_db
from ..models import User, Role
from ..auth import get_current_user, hash_password, verify_password, create_access_token
from ..dependencies import require_permission
from ..permissions import Permissions
from ..schemas import RegisterRequest

router = APIRouter(prefix="/users", tags=["Users"])


# ── Register ──────────────────────────────────────────────────────────────────

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register_user(
    body: RegisterRequest,
    db: Session = Depends(get_db)
):
    # Check username taken
    if db.query(User).filter(User.username == body.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")

    # Always assign the default role — never trust client for this
    default_role = db.query(Role).filter(Role.name == "student").first()
    if not default_role:
        raise HTTPException(
            status_code=500,
            detail="Default role not configured. Contact admin."
        )

    user = User(
        username=body.username,
        full_name=body.full_name,
        password=hash_password(body.password),
        role_id=default_role.id          # ← FK, not string
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return {"message": f"User '{user.username}' registered successfully"}


# ── Login ─────────────────────────────────────────────────────────────────────

@router.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.username == form_data.username).first()

    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Permissions are embedded into the JWT here
    access_token = create_access_token(
        user=user,                                   # ← new pattern
        expires_delta=timedelta(minutes=30)
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role.name,
        "permissions": [p.name for p in user.role.permissions]  # ← useful for Flutter
    }


# ── Get current user info ─────────────────────────────────────────────────────

@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "username": current_user.username,
        "full_name": current_user.full_name,
        "role": current_user.role.name,                              # ← .name not the object
        "permissions": [p.name for p in current_user.role.permissions]  # ← expose to Flutter
    }


# ── Admin: create user with specific role ─────────────────────────────────────

@router.post("/admin/create-user", status_code=status.HTTP_201_CREATED)
def admin_create_user(
    body: RegisterRequest,
    role_name: str = "student",
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    """
    Admin-only route to create a user with a specific role.
    Regular /register always assigns the default role.
    """
    if db.query(User).filter(User.username == body.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")

    role = db.query(Role).filter(Role.name == role_name).first()
    if not role:
        raise HTTPException(status_code=400, detail=f"Role '{role_name}' does not exist")

    user = User(
        username=body.username,
        full_name=body.full_name,
        password=hash_password(body.password),
        role_id=role.id
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return {"message": f"User '{user.username}' created with role '{role.name}'"}


# ── Admin: list all users ──────────────────────────────────────────────────────

@router.get("/all")
def get_all_users(
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    users = db.query(User).all()
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
    target_user = db.query(User).filter(User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    new_role = db.query(Role).filter(Role.name == role_name).first()
    if not new_role:
        raise HTTPException(status_code=400, detail=f"Role '{role_name}' does not exist")

    target_user.role_id = new_role.id
    db.commit()

    return {"message": f"'{target_user.username}' role changed to '{new_role.name}'"}