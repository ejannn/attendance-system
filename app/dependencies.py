from fastapi import Depends, HTTPException, status
from app.core.security import get_current_user
from app.models import User

def require_permission(permission: str):
    def checker(current_user: User = Depends(get_current_user)):
        # Use token permissions first (fast), fall back to DB if missing
        if hasattr(current_user, "_token_permissions"):
            user_permissions = current_user._token_permissions
        else:
            user_permissions = {p.name for p in current_user.role.permissions}

        if permission not in user_permissions:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied: '{permission}' required"
            )
        return current_user
    return checker