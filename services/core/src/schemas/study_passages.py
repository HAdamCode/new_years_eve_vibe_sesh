from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class StudyPassageCreate(BaseModel):
    book: str
    chapter: int
    start_verse: int | None = None
    end_verse: int | None = None
    version: str | None = None
    text: str | None = None


class StudyPassageUpdate(BaseModel):
    book: str | None = None
    chapter: int | None = None
    start_verse: int | None = None
    end_verse: int | None = None
    version: str | None = None
    text: str | None = None


class StudyPassageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    session_id: UUID
    book: str
    chapter: int
    start_verse: int | None
    end_verse: int | None
    version: str | None
    text: str | None
    created_at: datetime
