import os
import httpx  # You may need to pip install httpx if you don't have it
from typing import List, Optional
from .dtos import AttendanceSummaryDTO, EnrolledStudentDTO, StudentGradeDTO

GRADING_SYSTEM_URL = os.getenv("GRADING_SYSTEM_URL", "https://api.gradingsystem.com")

GRADING_API_KEY = os.getenv("GRADING_API_KEY", "grading-system-jwt-key-12345678910")

ENROLLMENT_SYSTEM_URL = os.getenv("ENROLLMENT_SYSTEM_URL", "https://api.enrollmentsystem.com")
ENROLLMENT_API_KEY = os.getenv("ENROLLMENT_API_KEY", "EnrollmentSystem-SecretKeyThatIsAtLeast32CharactersLongForSecurity12345")

class GradingSystemClient:
    """
    Client for SENDING data to the Grading System.
    """
    @staticmethod
    async def push_attendance_summaries(summaries: List[AttendanceSummaryDTO]):
        """
        Example of how you would push attendance data from your system 
        out to the Grading System actively.
        """
        headers = {
            "x-api-key": GRADING_API_KEY,
            "Content-Type": "application/json"
        }
        payload = {
            "source": "Attendance System",
            "summaries": [summary.model_dump() for summary in summaries]
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{GRADING_SYSTEM_URL}/webhooks/attendance-sync",
                    json=payload,
                    headers=headers,
                    timeout=10.0
                )
                response.raise_for_status()
                return {"success": True, "message": "Successfully pushed data to Grading System"}
            except Exception as e:
                print(f"Failed to push data to Grading System: {e}")
                return {"success": False, "message": str(e)}

    @staticmethod
    async def fetch_student_grades(username: str) -> Optional[List[StudentGradeDTO]]:
        """
        Example of PULLING data (GET request) from the Grading System.
        """
        headers = {"x-api-key": GRADING_API_KEY}
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(
                    f"{GRADING_SYSTEM_URL}/api/grades/{username}",
                    headers=headers,
                    timeout=10.0
                )
                response.raise_for_status()
                data = response.json()
                # Assuming their API returns a list of grades
                return [StudentGradeDTO(**grade) for grade in data.get("grades", [])]
            except Exception as e:
                print(f"Failed to fetch grades for {username}: {e}")
                return None


class EnrollmentSystemClient:
    """
    Client for PULLING data from the Enrollment System.
    """
    @staticmethod
    async def fetch_new_students() -> Optional[List[EnrolledStudentDTO]]:
        """
        Example of PULLING newly enrolled students using a GET request.
        """
        headers = {"x-api-key": ENROLLMENT_API_KEY}
        
        async with httpx.AsyncClient() as client:
            try:
                # Perhaps querying students enrolled in the last 24 hours
                response = await client.get(
                    f"{ENROLLMENT_SYSTEM_URL}/api/students/recent",
                    headers=headers,
                    timeout=10.0
                )
                response.raise_for_status()
                data = response.json()
                return [EnrolledStudentDTO(**student) for student in data.get("students", [])]
            except Exception as e:
                print(f"Failed to fetch new students: {e}")
                return None

