from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User, QuotaChangeLog
from app.middleware.auth import CurrentUser, get_current_user
from app.schemas.user import UserProfileResponse, ConsumeQuotaResponse, SyncRequest, SyncResponse
from app.utils.response import success, error
from app.utils.validator import mask_phone

router = APIRouter(prefix="/api/user", tags=["用户"])


def _user_to_profile(user: User) -> UserProfileResponse:
    return UserProfileResponse(
        id=str(user.id),
        phone=mask_phone(user.phone),
        nickname=user.nickname or f"用户{mask_phone(user.phone)}",
        avatar_url=user.avatar_url,
        ai_quota=user.ai_quota,
        total_score=user.total_score,
        level=user.level,
        is_admin=bool(user.is_admin),
    )


@router.get("/profile", response_model=UserProfileResponse)
async def get_profile(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == current_user.user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")
    return _user_to_profile(user)


@router.post("/consume-quota", response_model=ConsumeQuotaResponse)
async def consume_quota(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(User).where(User.id == current_user.user_id).with_for_update()
    )
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")

    if user.ai_quota <= 0:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="AI使用次数不足")

    before = user.ai_quota
    user.ai_quota -= 1
    after = user.ai_quota

    log = QuotaChangeLog(
        user_id=user.id,
        change_amount=-1,
        before_quota=before,
        after_quota=after,
        reason="智能解析消耗",
    )
    db.add(log)
    await db.flush()

    return ConsumeQuotaResponse(success=True, remaining_quota=after)


@router.post("/sync", response_model=SyncResponse)
async def sync_data(
    request: SyncRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(User).where(User.id == current_user.user_id).with_for_update()
    )
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="用户不存在")

    if request.total_score is not None:
        user.total_score = request.total_score
    if request.level is not None:
        user.level = request.level

    await db.flush()

    return SyncResponse(
        success=True,
        ai_quota=user.ai_quota,
        total_score=user.total_score,
        level=user.level,
    )
