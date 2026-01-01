from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class StudySessionCreate(BaseModel):
    title: str
    description: str | None = None
    position: int | None = None


class StudySessionUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    position: int | None = None


class StudySessionReorderItem(BaseModel):
    id: UUID
    position: int


class StudySessionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    study_id: UUID
    title: str
    description: str | None
    position: int
    created_at: datetime
    updated_at: datetime
