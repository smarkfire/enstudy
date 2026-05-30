from pydantic import BaseModel, Field


class UserProfileResponse(BaseModel):
    id: str
    phone: str
    nickname: str
    avatar_url: str
    ai_quota: int
    total_score: int
    level: int
    is_admin: bool


class ConsumeQuotaResponse(BaseModel):
    success: bool
    remaining_quota: int


class SyncRequest(BaseModel):
    total_score: int | None = None
    level: int | None = None


class SyncResponse(BaseModel):
    success: bool
    ai_quota: int
    total_score: int
    level: int
