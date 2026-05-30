from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.schemas.auth import SendCodeRequest, LoginRequest, LoginResponse, UserInfoResponse
from app.services.sms_service import send_verification_code
from app.services.code_service import verify_code
from app.services.auth_service import create_token
from app.utils.response import success, error
from app.utils.validator import mask_phone

router = APIRouter(prefix="/api/auth", tags=["认证"])


def _user_to_info(user: User) -> UserInfoResponse:
    return UserInfoResponse(
        id=str(user.id),
        phone=mask_phone(user.phone),
        nickname=user.nickname or f"用户{mask_phone(user.phone)}",
        avatar_url=user.avatar_url,
        ai_quota=user.ai_quota,
        total_score=user.total_score,
        level=user.level,
        is_admin=bool(user.is_admin),
    )


@router.post("/send-code")
async def send_code(request: SendCodeRequest):
    ok, message = await send_verification_code(request.phone)
    if not ok:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail=message)
    return success(message=message)


@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest, db: AsyncSession = Depends(get_db)):
    if not await verify_code(request.phone, request.code):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="验证码错误或已过期",
        )

    result = await db.execute(select(User).where(User.phone == request.phone))
    user = result.scalar_one_or_none()

    if user is None:
        user = User(
            phone=request.phone,
            nickname=f"用户{mask_phone(request.phone)}",
            ai_quota=10,
            created_at=datetime.now(timezone.utc),
        )
        db.add(user)
        await db.flush()
    else:
        user.last_login = datetime.now(timezone.utc)

    await db.flush()

    token = create_token(user.id, user.phone, bool(user.is_admin))
    user_info = _user_to_info(user)

    return LoginResponse(token=token, user=user_info)
