from pydantic import BaseModel
from typing import List

# Incoming DTOs
class StudentSyncRequest(BaseModel):
    username: str
    full_name: str

# Outgoing DTOs
class AttendanceSummaryDTO(BaseModel):
    id: int
    username: str
    full_name: str
    total_days_recorded: int
    days_attended: int
    attendance_rate_percent: float

class AttendanceSummaryResponse(BaseModel):
    status: str
    data: List[AttendanceSummaryDTO]

# DTOs for data we GET from other systems
class EnrolledStudentDTO(BaseModel):
    student_id: str
    username: str
    full_name: str
    course: str

class StudentGradeDTO(BaseModel):
    username: str
    subject: str
    grade: str
    passed: bool
