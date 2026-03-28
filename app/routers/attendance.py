from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models import User
from app.dependencies import require_permission
from app.permissions import Permissions
from app.services.attendance_service import AttendanceService

router = APIRouter(prefix="/attendance", tags=["Attendance"])


@router.post("/time-in")
def time_in(
    current_user: User = Depends(require_permission(Permissions.MARK_OWN_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    return AttendanceService.mark_time_in(db, current_user.id)


@router.post("/time-out")
def time_out(
    current_user: User = Depends(require_permission(Permissions.MARK_OWN_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    return AttendanceService.mark_time_out(db, current_user.id)


@router.post("/time-in/{user_id}")
def time_in_for_user(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.MARK_ANY_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    return AttendanceService.mark_time_in(db, user_id)


@router.post("/time-out/{user_id}")
def time_out_for_user(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.MARK_ANY_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    return AttendanceService.mark_time_out(db, user_id)


@router.get("/me")
def get_my_attendance(
    current_user: User = Depends(require_permission(Permissions.VIEW_OWN_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    return AttendanceService.get_user_records(db, current_user.id)


@router.get("/all")
def get_all_attendance(
    current_user: User = Depends(require_permission(Permissions.VIEW_ALL_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    return AttendanceService.get_all(db)


@router.get("/user/{user_id}")
def get_user_attendance(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.VIEW_ALL_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    return AttendanceService.get_user_records(db, user_id)