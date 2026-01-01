import uuid

from sqlalchemy import Column, DateTime, ForeignKey, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from db import Base


class StudyPassageLike(Base):
    __tablename__ = "study_passage_likes"
    __table_args__ = (
        UniqueConstraint(
            "passage_id",
            "group_id",
            "user_sub",
            name="uq_passage_like",
        ),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    passage_id = Column(
        UUID(as_uuid=True),
        ForeignKey("study_passages.id", ondelete="CASCADE"),
        nullable=False,
    )
    group_session_id = Column(
        UUID(as_uuid=True),
        ForeignKey("group_sessions.id", ondelete="CASCADE"),
        nullable=True,
    )
    group_id = Column(
        UUID(as_uuid=True),
        ForeignKey("groups.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_sub = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
