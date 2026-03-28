from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.user_repository import UserRepository, RoleRepository
from app.core.security import hash_password, verify_password
from app.models import User

class UserService:
    @staticmethod
    def register(db: Session, username: str, full_name: str, password: str) -> dict:
        if UserRepository.get_by_username(db, username):
            raise HTTPException(status_code=400, detail="Username already taken")

        default_role = RoleRepository.get_by_name(db, "student")
        if not default_role:
            raise HTTPException(status_code=500, detail="Default role not configured. Contact admin.")

        user = User(
            username=username,
            full_name=full_name,
            password=hash_password(password),
            role_id=default_role.id
        )
        UserRepository.create(db, user)
        return {"message": f"User '{user.username}' registered successfully"}

    @staticmethod
    def admin_create_user(db: Session, username: str, full_name: str, password: str, role_name: str) -> dict:
        if UserRepository.get_by_username(db, username):
            raise HTTPException(status_code=400, detail="Username already taken")

        role = RoleRepository.get_by_name(db, role_name)
        if not role:
            raise HTTPException(status_code=400, detail=f"Role '{role_name}' does not exist")

        user = User(
            username=username,
            full_name=full_name,
            password=hash_password(password),
            role_id=role.id
        )
        UserRepository.create(db, user)
        return {"message": f"User '{user.username}' created with role '{role.name}'", "id": user.id}

    @staticmethod
    def authenticate(db: Session, username: str, password: str) -> User | None:
        user = UserRepository.get_by_username(db, username)
        if not user or not verify_password(password, user.password):
            return None
        return user

    @staticmethod
    def get_all(db: Session):
        return UserRepository.get_all(db)

    @staticmethod
    def get_user(db: Session, user_id: int):
        user = UserRepository.get_by_id(db, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user

    @staticmethod
    def update_user(db: Session, user_id: int, current_user: User, username: str = None, password: str = None, full_name: str = None, role_name: str = None):
        target = UserRepository.get_by_id(db, user_id)
        if not target:
            raise HTTPException(status_code=404, detail="User not found")

        if username and username != target.username:
            if UserRepository.get_by_username(db, username):
                raise HTTPException(status_code=400, detail="Username already taken")
            target.username = username

        if password:
            target.password = hash_password(password)

        if full_name:
            target.full_name = full_name

        if role_name:
            new_role = RoleRepository.get_by_name(db, role_name)
            if not new_role:
                raise HTTPException(status_code=400, detail=f"Role '{role_name}' does not exist")
            if target.id == current_user.id and target.role.name == "admin" and role_name != "admin":
                raise HTTPException(status_code=400, detail="Cannot strip your own admin privileges")
            target.role_id = new_role.id

        UserRepository.update(db, target)
        return {"message": f"User '{target.username}' updated successfully"}

    @staticmethod
    def change_role(db: Session, user_id: int, current_user: User, role_name: str):
        if user_id == current_user.id:
            raise HTTPException(status_code=400, detail="You cannot change your own role")

        target = UserRepository.get_by_id(db, user_id)
        if not target:
            raise HTTPException(status_code=404, detail="User not found")

        new_role = RoleRepository.get_by_name(db, role_name)
        if not new_role:
            raise HTTPException(status_code=400, detail=f"Role '{role_name}' does not exist")

        old_role = target.role.name
        target.role_id = new_role.id
        UserRepository.update(db, target)

        return {"message": f"'{target.username}' role changed from '{old_role}' to '{new_role.name}'"}

    @staticmethod
    def delete(db: Session, user_id: int, current_user: User):
        if user_id == current_user.id:
            raise HTTPException(status_code=400, detail="You cannot delete yourself")

        target = UserRepository.get_by_id(db, user_id)
        if not target:
            raise HTTPException(status_code=404, detail="User not found")

        username = target.username
        UserRepository.delete(db, target)
        return {"message": f"User '{username}' deleted successfully"}
