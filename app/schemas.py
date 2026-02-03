from pydantic import BaseModel

# ================= USERS =================

class UserCreate(BaseModel):
    username: str
    password: str
    


class UserLogin(BaseModel):
    username: str
    password: str


class UserOut(BaseModel):
    id: int
    username: str
    role: str

    class Config:
        from_attributes = True  # SQLAlchemy compatibility


# ================= ATTENDANCE =================

class AttendanceOut(BaseModel):
    id: int
    username: str
    date: str
    time_in: str | None
    time_out: str | None
