from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class StudySessionNoteCreate(BaseModel):
    note: str


class StudySessionNoteUpdate(BaseModel):
    note: str


class StudySessionNoteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    session_id: UUID
    group_id: UUID
    user_sub: str
    note: str
    created_at: datetime
    updated_at: datetime
