from pydantic import BaseModel, Field
import re


def validate_phone(phone: str) -> str:
    if not re.match(r"^1[3-9]\d{9}$", phone):
        raise ValueError("手机号格式不正确")
    return phone


class SendCodeRequest(BaseModel):
    phone: str = Field(..., description="手机号")

    def model_post_init(self, __context):
        self.phone = validate_phone(self.phone)


class LoginRequest(BaseModel):
    phone: str = Field(..., description="手机号")
    code: str = Field(..., min_length=6, max_length=6, description="6位验证码")

    def model_post_init(self, __context):
        self.phone = validate_phone(self.phone)


class LoginResponse(BaseModel):
    token: str
    user: "UserInfoResponse"


class UserInfoResponse(BaseModel):
    id: str
    phone: str
    nickname: str
    avatar_url: str
    ai_quota: int
    total_score: int
    level: int
    is_admin: bool
