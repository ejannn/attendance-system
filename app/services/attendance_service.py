from sqlalchemy.orm import Session
from fastapi import HTTPException
from datetime import datetime, date
from app.repositories.attendance_repository import AttendanceRepository
from app.repositories.user_repository import UserRepository
from app.models import Attendance, AttendanceStatus, User

class AttendanceService:
    LATE_THRESHOLD_HOUR = 9

    @staticmethod
    def _resolve_status(time_in: datetime) -> AttendanceStatus:
        if time_in.hour >= AttendanceService.LATE_THRESHOLD_HOUR:
            return AttendanceStatus.late
        return AttendanceStatus.present

    @staticmethod
    def mark_time_in(db: Session, target_user_id: int) -> dict:
        target = UserRepository.get_by_id(db, target_user_id)
        if not target:
            raise HTTPException(status_code=404, detail="User not found")

        if AttendanceRepository.get_todays_record(db, target_user_id):
            raise HTTPException(status_code=400, detail=f"{target.username} already timed in today")

        now = datetime.utcnow()
        record = Attendance(
            user_id=target_user_id,
            date=date.today(),
            time_in=now,
            status=AttendanceService._resolve_status(now)
        )
        record = AttendanceRepository.create(db, record)

        return {"message": f"Time-in recorded for {target.username}", "status": record.status}

    @staticmethod
    def mark_time_out(db: Session, target_user_id: int) -> dict:
        target = UserRepository.get_by_id(db, target_user_id)
        if not target:
            raise HTTPException(status_code=404, detail="User not found")

        record = AttendanceRepository.get_todays_record(db, target_user_id)
        if not record:
            raise HTTPException(status_code=400, detail=f"No time-in record found for {target.username}")

        if record.time_out:
            raise HTTPException(status_code=400, detail=f"{target.username} already timed out today")

        record.time_out = datetime.utcnow()
        AttendanceRepository.update(db, record)

        return {"message": f"Time-out recorded for {target.username}"}

    @staticmethod
    def get_dashboard_stats(db: Session) -> dict:
        total_users = UserRepository.count(db)
        present_today = AttendanceRepository.count_present_today(db)
        
        attendance_rate = 0
        if total_users > 0:
            attendance_rate = round((present_today / total_users) * 100, 1)

        return {
            "total_users": total_users,
            "present_today": present_today,
            "attendance_rate": attendance_rate
        }

    @staticmethod
    def get_all(db: Session):
        return AttendanceRepository.get_all(db)

    @staticmethod
    def get_user_records(db: Session, user_id: int):
        target = UserRepository.get_by_id(db, user_id)
        if not target:
            raise HTTPException(status_code=404, detail="User not found")
        return AttendanceRepository.get_by_user(db, user_id)
