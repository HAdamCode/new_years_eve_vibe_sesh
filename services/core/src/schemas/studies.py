from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class StudyCreate(BaseModel):
    title: str
    description: str | None = None


class StudyUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    is_archived: bool | None = None


class StudyOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    group_id: UUID
    title: str
    description: str | None
    is_archived: bool
    created_at: datetime
    updated_at: datetime
