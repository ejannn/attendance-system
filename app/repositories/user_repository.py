from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from app.models import User, Role

class UserRepository:
    @staticmethod
    def get_by_id(db: Session, user_id: int) -> Optional[User]:
        return db.query(User).filter(User.id == user_id).first()

    @staticmethod
    def get_by_username(db: Session, username: str) -> Optional[User]:
        return db.query(User).filter(User.username == username).first()

    @staticmethod
    def get_all(db: Session) -> List[User]:
        return db.query(User).all()

    @staticmethod
    def count(db: Session) -> int:
        return db.query(func.count(User.id)).scalar() or 0

    @staticmethod
    def create(db: Session, user: User) -> User:
        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def update(db: Session, user: User) -> User:
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def delete(db: Session, user: User) -> None:
        db.delete(user)
        db.commit()


class RoleRepository:
    @staticmethod
    def get_by_name(db: Session, name: str) -> Optional[Role]:
        return db.query(Role).filter(Role.name == name).first()
