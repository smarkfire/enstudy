import uuid
from datetime import datetime

from sqlalchemy import String, Integer, SmallInteger, Index
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)
    nickname: Mapped[str] = mapped_column(String(50), default="")
    avatar_url: Mapped[str] = mapped_column(String(500), default="")
    ai_quota: Mapped[int] = mapped_column(Integer, default=10)
    total_score: Mapped[int] = mapped_column(Integer, default=0)
    level: Mapped[int] = mapped_column(Integer, default=1)
    is_admin: Mapped[int] = mapped_column(SmallInteger, default=0)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP, nullable=False, default=datetime.utcnow)
    last_login: Mapped[datetime | None] = mapped_column(TIMESTAMP, nullable=True)

    __table_args__ = (
        Index("idx_users_phone", "phone"),
        Index("idx_users_is_admin", "is_admin"),
    )


class QuotaChangeLog(Base):
    __tablename__ = "quota_change_logs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    change_amount: Mapped[int] = mapped_column(Integer, nullable=False)
    before_quota: Mapped[int] = mapped_column(Integer, nullable=False)
    after_quota: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[str] = mapped_column(String(200), nullable=False)
    operator_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP, nullable=False, default=datetime.utcnow)

    __table_args__ = (
        Index("idx_quota_logs_user_id", "user_id"),
        Index("idx_quota_logs_created_at", "created_at"),
    )
