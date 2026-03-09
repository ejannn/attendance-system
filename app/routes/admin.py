# app/routes/admin.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date
from app.database import get_db
from app.models import Attendance, User, Role
from app.dependencies import require_permission
from app.permissions import Permissions
from app.schemas import AdminCreateUserRequest, AdminUpdateUserRequest, UserOut
from app.auth import hash_password
from app.permissions import Permissions

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/dashboard-stats")
def get_dashboard_stats(
    current_user: User = Depends(require_permission(Permissions.VIEW_ALL_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    total_users = db.query(func.count(User.id)).scalar() or 0
    present_today = (
        db.query(func.count(func.distinct(Attendance.user_id)))
        .filter(Attendance.date == date.today())
        .scalar() or 0
    )
    
    attendance_rate = 0
    if total_users > 0:
        attendance_rate = round((present_today / total_users) * 100, 1)

    return {
        "total_users": total_users,
        "present_today": present_today,
        "attendance_rate": attendance_rate
    }


@router.get("/attendance")
def view_all_attendance(
    current_user: User = Depends(require_permission(Permissions.VIEW_ALL_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    records = (
        db.query(Attendance)
        .join(User)
        .order_by(Attendance.date.desc(), Attendance.time_in.desc())
        .all()
    )

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


@router.get("/users/{user_id}", response_model=UserOut)
def get_user(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    
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
    if db.query(User).filter(User.username == body.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")

    role = db.query(Role).filter(Role.name == body.role).first()
    if not role:
        raise HTTPException(status_code=400, detail=f"Role '{body.role}' does not exist")

    user = User(
        username=body.username,
        full_name=body.full_name,
        password=hash_password(body.password),
        role_id=role.id
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return {"message": f"User '{user.username}' created successfully", "id": user.id}


@router.put("/users/{user_id}")
def update_user(
    user_id: int,
    body: AdminUpdateUserRequest,
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    if body.username and body.username != target.username:
        if db.query(User).filter(User.username == body.username).first():
            raise HTTPException(status_code=400, detail="Username already taken")
        target.username = body.username

    if body.password:
        target.password = hash_password(body.password)

    if body.full_name is not None:
        target.full_name = body.full_name

    if body.role:
        new_role = db.query(Role).filter(Role.name == body.role).first()
        if not new_role:
            raise HTTPException(status_code=400, detail=f"Role '{body.role}' does not exist")
        # Ensure they don't lock themselves out of admin if they are updating their own role to non-admin
        if target.id == current_user.id and target.role.name == "admin" and body.role != "admin":
            raise HTTPException(status_code=400, detail="Cannot strip your own admin privileges")
        target.role_id = new_role.id

    db.commit()

    return {"message": f"User '{target.username}' updated successfully"}


@router.put("/promote/{user_id}")
def change_user_role(
    user_id: int,
    role_name: str,                  # pass as query param: /admin/promote/3?role_name=teacher
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    # Can't promote yourself
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot change your own role")

    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    new_role = db.query(Role).filter(Role.name == role_name).first()
    if not new_role:
        raise HTTPException(status_code=400, detail=f"Role '{role_name}' does not exist")

    old_role = target.role.name
    target.role_id = new_role.id     # ← FK assignment, not string
    db.commit()

    return {
        "message": f"'{target.username}' role changed from '{old_role}' to '{new_role.name}'"
    }


@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.MANAGE_USERS)),
    db: Session = Depends(get_db)
):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot delete yourself")

    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(target)
    db.commit()

    return {"message": f"User '{target.username}' deleted successfully"}