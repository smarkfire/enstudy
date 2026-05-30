import uuid
from datetime import datetime, timedelta, timezone

from jose import jwt, JWTError

from app.config import settings


def create_token(user_id: uuid.UUID, phone: str, is_admin: bool) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.JWT_EXPIRE_DAYS)
    payload = {
        "userId": str(user_id),
        "phone": phone,
        "isAdmin": is_admin,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm="HS256")


def decode_token(token: str) -> dict | None:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
        return payload
    except JWTError:
        return None
