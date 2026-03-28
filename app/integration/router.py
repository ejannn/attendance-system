import os
from fastapi import APIRouter, HTTPException, Security, Depends
from fastapi.security.api_key import APIKeyHeader
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.database import get_db
from app.models import User, Role, Attendance, AttendanceStatus
from app.core.security import hash_password
from app.integration.dtos import StudentSyncRequest, AttendanceSummaryDTO, AttendanceSummaryResponse

router = APIRouter(prefix="/integration", tags=["Integration"])

API_KEY = os.getenv("ATTENDANCE_APP_KEY")

api_key_header = APIKeyHeader(name="x-api-key", auto_error=False)

def verify_api_key(api_key: str = Security(api_key_header)):
    if not API_KEY or api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

@router.post("/students")
def sync_student(
    data: StudentSyncRequest, 
    x_api_key: str = Depends(verify_api_key),
    db: Session = Depends(get_db)
):
    """
    Receives newly enrolled students from the Enrollment System and creates them here.
    """
    existing_user = db.query(User).filter(User.username == data.username).first()
    if existing_user:
        return {"status": "skipped", "message": "Student already exists"}

    student_role = db.query(Role).filter(Role.name == "student").first()
    if not student_role:
        raise HTTPException(status_code=500, detail="Student role configuration missing")

    new_user = User(
        username=data.username,
        full_name=data.full_name,
        password=hash_password("changeme123"),
        role_id=student_role.id
    )
    
    db.add(new_user)
    db.commit()
    return {"status": "success", "message": f"Student '{data.username}' synced to Attendance System."}


@router.get("/attendance-summary", response_model=AttendanceSummaryResponse)
def get_attendance_summary(
    x_api_key: str = Depends(verify_api_key),
    db: Session = Depends(get_db)
):
    """
    Returns an attendance metric summary for all students so the Grading System can process it.
    """
    student_role = db.query(Role).filter(Role.name == "student").first()
    if not student_role:
        raise HTTPException(status_code=500, detail="Student role configuration missing")

    students = db.query(User).filter(User.role_id == student_role.id).all()
    
    results = []
    for student in students:
        total_records = db.query(Attendance).filter(Attendance.user_id == student.id).count()
        
        present_count = db.query(Attendance).filter(
            Attendance.user_id == student.id,
            Attendance.status.in_([AttendanceStatus.present, AttendanceStatus.late, AttendanceStatus.half_day])
        ).count()
        
        rate = 0.0
        if total_records > 0:
            rate = round((present_count / total_records) * 100, 1)

        summary_dto = AttendanceSummaryDTO(
            id=student.id,
            username=student.username,
            full_name=student.full_name or "Unknown",
            total_days_recorded=total_records,
            days_attended=present_count,
            attendance_rate_percent=rate
        )
        results.append(summary_dto)

    return AttendanceSummaryResponse(status="success", data=results)
