from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class StudyQuestionCreate(BaseModel):
    question: str
    position: int | None = None


class StudyQuestionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    session_id: UUID
    question: str
    position: int
    created_at: datetime
