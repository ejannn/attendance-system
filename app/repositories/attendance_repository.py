from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, datetime
from typing import List, Optional
from app.models import Attendance, User

class AttendanceRepository:
    @staticmethod
    def get_todays_record(db: Session, user_id: int) -> Optional[Attendance]:
        return (
            db.query(Attendance)
            .filter(
                Attendance.user_id == user_id,
                Attendance.date == date.today()
            )
            .first()
        )

    @staticmethod
    def create(db: Session, record: Attendance) -> Attendance:
        db.add(record)
        db.commit()
        db.refresh(record)
        return record

    @staticmethod
    def update(db: Session, record: Attendance) -> Attendance:
        db.commit()
        db.refresh(record)
        return record

    @staticmethod
    def get_all(db: Session) -> List[Attendance]:
        return (
            db.query(Attendance)
            .join(User)
            .order_by(Attendance.date.desc(), Attendance.time_in.desc())
            .all()
        )

    @staticmethod
    def get_by_user(db: Session, user_id: int) -> List[Attendance]:
        return (
            db.query(Attendance)
            .filter(Attendance.user_id == user_id)
            .order_by(Attendance.date.desc())
            .all()
        )

    @staticmethod
    def count_present_today(db: Session) -> int:
        return (
            db.query(func.count(func.distinct(Attendance.user_id)))
            .filter(Attendance.date == date.today())
            .scalar() or 0
        )
