import uuid
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.services.auth_service import decode_token

security = HTTPBearer()


class CurrentUser:
    def __init__(self, user_id: uuid.UUID, phone: str, is_admin: bool):
        self.user_id = user_id
        self.phone = phone
        self.is_admin = is_admin


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> CurrentUser:
    payload = decode_token(credentials.credentials)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的认证凭据",
        )
    try:
        user_id = uuid.UUID(payload["userId"])
        phone = payload["phone"]
        is_admin = payload.get("isAdmin", False)
    except (KeyError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的Token内容",
        )
    return CurrentUser(user_id=user_id, phone=phone, is_admin=is_admin)


async def require_admin(
    current_user: CurrentUser = Depends(get_current_user),
) -> CurrentUser:
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="需要管理员权限",
        )
    return current_user
