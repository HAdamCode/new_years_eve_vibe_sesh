import uuid

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from db import Base


class StudyPassage(Base):
    __tablename__ = "study_passages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(
        UUID(as_uuid=True),
        ForeignKey("study_sessions.id", ondelete="CASCADE"),
        nullable=False,
    )
    book = Column(String(120), nullable=False)
    chapter = Column(Integer, nullable=False)
    start_verse = Column(Integer, nullable=True)
    end_verse = Column(Integer, nullable=True)
    version = Column(String(20), nullable=True)
    text = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
