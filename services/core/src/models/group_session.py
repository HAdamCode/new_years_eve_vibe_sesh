import uuid

from sqlalchemy import Column, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from db import Base


class GroupSession(Base):
    __tablename__ = "group_sessions"
    __table_args__ = (
        UniqueConstraint("group_study_id", "study_session_id", name="uq_group_session"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    group_study_id = Column(
        UUID(as_uuid=True),
        ForeignKey("group_studies.id", ondelete="CASCADE"),
        nullable=False,
    )
    study_session_id = Column(
        UUID(as_uuid=True),
        ForeignKey("study_sessions.id", ondelete="CASCADE"),
        nullable=False,
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
