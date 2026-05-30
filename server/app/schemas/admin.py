from pydantic import BaseModel, Field
import uuid


class AdminUserItem(BaseModel):
    id: str
    phone: str
    nickname: str
    avatar_url: str
    ai_quota: int
    total_score: int
    level: int
    is_admin: bool
    created_at: str
    last_login: str | None


class AdminUserListResponse(BaseModel):
    total: int
    page: int
    page_size: int
    users: list[AdminUserItem]


class UpdateQuotaRequest(BaseModel):
    user_id: str = Field(..., description="目标用户ID")
    change: int = Field(..., description="变更数量，正数增加，负数减少")


class UpdateQuotaResponse(BaseModel):
    success: bool
    new_quota: int
