# app/seed.py
from app.database import SessionLocal, engine
from app.models import Base, Role, Permission, RolePermission, User
from app.permissions import Permissions
from app.auth import hash_password

ROLE_PERMISSIONS = {
    "admin": {
        "description": "Full system access — can manage users, view all records, and mark attendance for anyone",
        "permissions": [
            Permissions.MARK_OWN_ATTENDANCE,
            Permissions.MARK_ANY_ATTENDANCE,
            Permissions.VIEW_OWN_ATTENDANCE,
            Permissions.VIEW_ALL_ATTENDANCE,
            Permissions.MANAGE_USERS,
        ]
    },
    "teacher": {
        "description": "Can mark attendance for students and view all attendance records",
        "permissions": [
            Permissions.MARK_OWN_ATTENDANCE,
            Permissions.MARK_ANY_ATTENDANCE,
            Permissions.VIEW_OWN_ATTENDANCE,
            Permissions.VIEW_ALL_ATTENDANCE,
        ]
    },
    "manager": {
        "description": "Can view all attendance records and reports but cannot mark attendance",
        "permissions": [
            Permissions.VIEW_OWN_ATTENDANCE,
            Permissions.VIEW_ALL_ATTENDANCE,
        ]
    },
    "employee": {
        "description": "Can mark own attendance and view own records only",
        "permissions": [
            Permissions.MARK_OWN_ATTENDANCE,
            Permissions.VIEW_OWN_ATTENDANCE,
        ]
    },
    "student": {
        "description": "Can mark own attendance and view own records only",
        "permissions": [
            Permissions.MARK_OWN_ATTENDANCE,
            Permissions.VIEW_OWN_ATTENDANCE,
        ]
    },
}


def seed():
    # Step 1 — create all tables
    print("📦 Creating tables...")
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        # Step 2 — seed permissions
        all_permissions = [
            value for key, value in Permissions.__dict__.items()
            if not key.startswith("_") and isinstance(value, str)
        ]

        print(f"🔑 Seeding {len(all_permissions)} permissions...")
        for perm_name in all_permissions:
            exists = db.query(Permission).filter(Permission.name == perm_name).first()
            if not exists:
                db.add(Permission(name=perm_name))
                print(f"   + permission: {perm_name}")

        db.commit()

        # Step 3 — seed roles + assign permissions
        print("👥 Seeding roles...")
        for role_name, role_data in ROLE_PERMISSIONS.items():
            role = db.query(Role).filter(Role.name == role_name).first()

            if not role:
                role = Role(
                    name=role_name,
                    description=role_data["description"]
                )
                db.add(role)
                db.commit()
                db.refresh(role)
                print(f"   + role: {role_name}")
            else:
                # Update description if role already exists
                role.description = role_data["description"]
                db.commit()
                print(f"   ~ role already exists, updated description: {role_name}")

            # Step 4 — assign permissions to role
            for perm_name in role_data["permissions"]:
                perm = db.query(Permission).filter(Permission.name == perm_name).first()
                if not perm:
                    print(f"   ⚠️  Permission '{perm_name}' not found, skipping")
                    continue

                exists = db.query(RolePermission).filter_by(
                    role_id=role.id,
                    permission_id=perm.id
                ).first()

                if not exists:
                    db.add(RolePermission(role_id=role.id, permission_id=perm.id))
                    print(f"      → assigned '{perm_name}' to '{role_name}'")

        db.commit()

        # Step 5 — seed default admin and student users
        print("👤 Seeding default users...")
        admin_role = db.query(Role).filter(Role.name == "admin").first()
        student_role = db.query(Role).filter(Role.name == "student").first()

        if admin_role:
            admin_user = db.query(User).filter(User.username == "admin").first()
            if not admin_user:
                db.add(User(
                    username="admin",
                    full_name="System Admin",
                    password=hash_password("admin123"),
                    role_id=admin_role.id
                ))
                print("   + user: admin (password: admin123)")

        if student_role:
            student_user = db.query(User).filter(User.username == "student").first()
            if not student_user:
                db.add(User(
                    username="student",
                    full_name="Demo Student",
                    password=hash_password("student123"),
                    role_id=student_role.id
                ))
                print("   + user: student (password: student123)")

        db.commit()
        print("\n✅ Seed complete")

    except Exception as e:
        db.rollback()
        print(f"\n❌ Seed failed: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()