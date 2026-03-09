from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, date
from app.database import get_db
from app.models import Attendance, AttendanceStatus, User
from app.dependencies import require_permission
from app.permissions import Permissions

router = APIRouter(prefix="/attendance", tags=["Attendance"])

# ── Helpers ──────────────────────────────────────────────────────────────────

LATE_THRESHOLD_HOUR = 9  # anyone timing in after 9AM is "late"

def _resolve_status(time_in: datetime) -> AttendanceStatus:
    """Determine attendance status based on time_in."""
    if time_in.hour >= LATE_THRESHOLD_HOUR:
        return AttendanceStatus.late
    return AttendanceStatus.present


def _get_todays_record(db: Session, user_id: int) -> Attendance | None:
    return (
        db.query(Attendance)
        .filter(
            Attendance.user_id == user_id,
            Attendance.date == date.today()
        )
        .first()
    )


# ── Self time-in/out (student, employee, teacher) ────────────────────────────

@router.post("/time-in")
def time_in(
    current_user: User = Depends(require_permission(Permissions.MARK_OWN_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    if _get_todays_record(db, current_user.id):
        raise HTTPException(status_code=400, detail="Already timed in today")

    now = datetime.utcnow()
    record = Attendance(
        user_id=current_user.id,
        date=date.today(),
        time_in=now,
        status=_resolve_status(now)
    )

    db.add(record)
    db.commit()

    return {"message": "Time-in recorded", "status": record.status}


@router.post("/time-out")
def time_out(
    current_user: User = Depends(require_permission(Permissions.MARK_OWN_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    record = _get_todays_record(db, current_user.id)

    if not record:
        raise HTTPException(status_code=400, detail="No time-in record found for today")

    if record.time_out:
        raise HTTPException(status_code=400, detail="Already timed out today")

    record.time_out = datetime.utcnow()
    db.commit()

    return {"message": "Time-out recorded"}


# ── Admin/Teacher override routes ─────────────────────────────────────────────

@router.post("/time-in/{user_id}")
def time_in_for_user(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.MARK_ANY_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    # Make sure the target user exists
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    if _get_todays_record(db, user_id):
        raise HTTPException(status_code=400, detail=f"{target.username} already timed in today")

    now = datetime.utcnow()
    record = Attendance(
        user_id=user_id,
        date=date.today(),
        time_in=now,
        status=_resolve_status(now)
    )

    db.add(record)
    db.commit()

    return {"message": f"Time-in recorded for {target.username}", "status": record.status}


@router.post("/time-out/{user_id}")
def time_out_for_user(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.MARK_ANY_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    record = _get_todays_record(db, user_id)

    if not record:
        raise HTTPException(status_code=400, detail=f"No time-in record found for {target.username}")

    if record.time_out:
        raise HTTPException(status_code=400, detail=f"{target.username} already timed out today")

    record.time_out = datetime.utcnow()
    db.commit()

    return {"message": f"Time-out recorded for {target.username}"}


# ── View routes ───────────────────────────────────────────────────────────────

@router.get("/me")
def get_my_attendance(
    current_user: User = Depends(require_permission(Permissions.VIEW_OWN_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    records = (
        db.query(Attendance)
        .filter(Attendance.user_id == current_user.id)
        .order_by(Attendance.date.desc())
        .all()
    )
    return records


@router.get("/all")
def get_all_attendance(
    current_user: User = Depends(require_permission(Permissions.VIEW_ALL_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    records = (
        db.query(Attendance)
        .order_by(Attendance.date.desc())
        .all()
    )
    return records


@router.get("/user/{user_id}")
def get_user_attendance(
    user_id: int,
    current_user: User = Depends(require_permission(Permissions.VIEW_ALL_ATTENDANCE)),
    db: Session = Depends(get_db)
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    records = (
        db.query(Attendance)
        .filter(Attendance.user_id == user_id)
        .order_by(Attendance.date.desc())
        .all()
    )
    return records