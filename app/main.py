from fastapi import FastAPI
from .database import engine
from . import models
from .routes import users, attendance
from app.routes import admin
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI(title="Attendance System API")


models.Base.metadata.create_all(bind=engine)

app.include_router(users.router)
app.include_router(attendance.router)
app.include_router(admin.router)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all (dev only)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
