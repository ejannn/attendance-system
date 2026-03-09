# schemas.py
from pydantic import BaseModel, field_validator


class RegisterRequest(BaseModel):
    username: str
    password: str
    full_name: str | None = None

    @field_validator("username")
    def username_must_be_valid(cls, v):
        if len(v) < 3:
            raise ValueError("Username must be at least 3 characters")
        return v.strip()

    @field_validator("password")
    def password_must_be_strong(cls, v):
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v


class AdminCreateUserRequest(BaseModel):
    username: str
    password: str
    full_name: str | None = None
    role: str = "student"

    @field_validator("username")
    def username_must_be_valid(cls, v):
        if len(v) < 3:
            raise ValueError("Username must be at least 3 characters")
        return v.strip()

    @field_validator("password")
    def password_must_be_strong(cls, v):
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v


class AdminUpdateUserRequest(BaseModel):
    username: str | None = None
    password: str | None = None
    full_name: str | None = None
    role: str | None = None


class UserOut(BaseModel):
    id: int
    username: str
    full_name: str | None = None
    role: str

    class Config:
        from_attributes = True  # allows SQLAlchemy model → Pydantic conversion