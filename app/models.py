import enum

from sqlalchemy import Column, Enum, Integer, String, DateTime, ForeignKey , Date, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base
from sqlalchemy.sql import func


class Role(Base):
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)
    description = Column(String, nullable=True)
    permissions = relationship("Permission", secondary="role_permissions")

class Permission(Base):
    __tablename__ = "permissions"
    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)

class RolePermission(Base):
    __tablename__ = "role_permissions"
    role_id = Column(ForeignKey("roles.id"), primary_key=True)
    permission_id = Column(ForeignKey("permissions.id"), primary_key=True)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    full_name = Column(String, nullable=True)
    password = Column(String)
    role_id = Column(ForeignKey("roles.id"))
    role = relationship("Role")
    attendance = relationship("Attendance", back_populates="user")

class AttendanceStatus(str, enum.Enum):
    present = "present"
    late = "late"
    absent = "absent"
    half_day = "half_day"
    


class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    date = Column(Date, default=lambda: datetime.utcnow().date())
    time_in = Column(DateTime, server_default=func.now())
    time_out = Column(DateTime, nullable=True)
    status = Column(Enum(AttendanceStatus), default=AttendanceStatus.present)

    user = relationship("User", back_populates="attendance")

    __table_args__ = (
        UniqueConstraint("user_id", "date", name="uq_user_attendance_date"),  # ← prevent duplicates
    )
