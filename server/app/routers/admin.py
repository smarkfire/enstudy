from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User, QuotaChangeLog
from app.middleware.auth import CurrentUser, require_admin
from app.schemas.admin import AdminUserItem, AdminUserListResponse, UpdateQuotaRequest, UpdateQuotaResponse
from app.utils.validator import mask_phone

router = APIRouter(prefix="/api/admin", tags=["管理员"])


def _user_to_item(user: User) -> AdminUserItem:
    return AdminUserItem(
        id=str(user.id),
        phone=mask_phone(user.phone),
        nickname=user.nickname or f"用户{mask_phone(user.phone)}",
        avatar_url=user.avatar_url,
        ai_quota=user.ai_quota,
        total_score=user.total_score,
        level=user.level,
        is_admin=bool(user.is_admin),
        created_at=user.created_at.isoformat() if user.created_at else "",
        last_login=user.last_login.isoformat() if user.last_login else None,
    )


@router.get("/users", response_model=AdminUserListResponse)
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str | None = Query(None),
    admin: CurrentUser = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(User)
    count_query = select(func.count()).select_from(User)

    if search:
        like = f"%{search}%"
        query = query.where(User.phone.ilike(like) | User.nickname.ilike(like))
        count_query = count_query.where(User.phone.ilike(like) | User.nickname.ilike(like))

    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    query = query.order_by(User.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    users = result.scalars().all()

    return AdminUserListResponse(
        total=total,
        page=page,
        page_size=page_size,
        users=[_user_to_item(u) for u in users],
    )


@router.post("/update-quota", response_model=UpdateQuotaResponse)
async def update_quota(
    request: UpdateQuotaRequest,
    admin: CurrentUser = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    import uuid

    try:
        target_id = uuid.UUID(request.user_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="无效的用户ID")

    result = await db.execute(select(User).where(User.id == target_id).with_for_update())
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="目标用户不存在")

    before = user.ai_quota
    user.ai_quota += request.change
    if user.ai_quota < 0:
        user.ai_quota = 0
    after = user.ai_quota

    log = QuotaChangeLog(
        user_id=user.id,
        change_amount=request.change,
        before_quota=before,
        after_quota=after,
        reason=f"管理员充值{request.change}次",
        operator_id=admin.user_id,
    )
    db.add(log)
    await db.flush()

    return UpdateQuotaResponse(success=True, new_quota=after)
