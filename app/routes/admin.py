# app/routes/admin.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Attendance, User
from app.auth import get_current_user
from typing import List
from app.schemas import UserOut

router = APIRouter(prefix="/admin", tags=["Admin"])

def admin_required(current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user

@router.get("/attendance")
def view_all_attendance(db: Session = Depends(get_db), current_user: User = Depends(admin_required)):
    """
    Returns all attendance records ordered by date descending.
    """
    records = (
        db.query(Attendance)
        .join(User)
        .order_by(Attendance.date.desc(), Attendance.time_in.desc())
        .all()
    )

    result = []
    for r in records:
        result.append({
            "id": r.id,
            "username": r.user.username,
            "date": r.date.isoformat(),
            "time_in": r.time_in.isoformat() if r.time_in else None,
            "time_out": r.time_out.isoformat() if r.time_out else None
        })

    return {"attendance": result}

@router.put("/promote/{user_id}")
def promote_user_to_admin(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(admin_required)
):
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(404, "User not found")

    if user.role == "admin":
        return {"message": "User is already an admin"}

    user.role = "admin"
    db.commit()

    return {
        "message": "User promoted to admin",
        "username": user.username
    }
