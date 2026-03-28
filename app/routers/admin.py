from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models import User
from app.dependencies import require_permission
from app.permissions import Permissions
from app.schemas import AdminCreateUserRequest, AdminUpdateUserRequest, UserOut
from app.services.user_service import UserService
from app.services.attendance_service import AttendanceService

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/dashboard-stats")
def get_dashboard_stats(
    current_user: User = Depends(require_permission(Permissions.VIEW_ALL_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    return AttendanceService.get_dashboard_stats(db)


@router.get("/attendance")
def view_all_attendance(
    current_user: User = Depends(require_permission(Permissions.VIEW_ALL_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    records = AttendanceService.get_all(db)
    return {
        "attendance": [
            {
                "id": r.id,
                "user_id": r.user.id,
                "username": r.user.username,
                "full_name": r.user.full_name,
                "date": r.date.isoformat(),
                "time_in": r.time_in.isoformat() if r.time_in else None,
                "time_out": r.time_out.isoformat() if r.time_out else None,
                "status": r.status
            }
            for r in records
        ]
    }


@router.get("/users")
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


@router.get("/users/{user_id}", response_model=UserOut)
def get_user(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    target = UserService.get_user(db, user_id)
    return {
        "id": target.id,
        "username": target.username,
        "full_name": target.full_name,
        "role": target.role.name
    }


@router.post("/users", status_code=201)
def create_user(
    body: AdminCreateUserRequest,
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    return UserService.admin_create_user(db, body.username, body.full_name, body.password, body.role)


@router.put("/users/{user_id}")
def update_user(
    user_id: int,
    body: AdminUpdateUserRequest,
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    return UserService.update_user(
        db, user_id, current_user, 
        username=body.username, password=body.password, 
        full_name=body.full_name, role_name=body.role
    )


@router.put("/promote/{user_id}")
def change_user_role(
    user_id: int,
    role_name: str,
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    return UserService.change_role(db, user_id, current_user, role_name)


@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    return UserService.delete(db, user_id, current_user)