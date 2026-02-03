from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, date
from app.database import get_db
from app.models import Attendance, User
from app.auth import get_current_user

router = APIRouter(prefix="/attendance", tags=["Attendance"])


@router.post("/time-in")
def time_in(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    today = date.today()

    existing = (
        db.query(Attendance)
        .filter(
            Attendance.user_id == current_user.id,
            Attendance.date == today
        )
        .first()
    )

    if existing:
        raise HTTPException(status_code=400, detail="Already timed in today")

    record = Attendance(
        user_id=current_user.id,
        date=today,
        time_in=datetime.utcnow()
    )

    db.add(record)
    db.commit()

    return {"message": "Time-in recorded"}


@router.post("/time-out")
def time_out(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    today = date.today()

    record = (
        db.query(Attendance)
        .filter(
            Attendance.user_id == current_user.id,
            Attendance.date == today,
            Attendance.time_out.is_(None)
        )
        .first()
    )

    if not record:
        raise HTTPException(status_code=400, detail="No active time-in today")

    record.time_out = datetime.utcnow()
    db.commit()

    return {"message": "Time-out recorded"}
