from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class StudyQuestionResponseCreate(BaseModel):
    response: str
    parent_response_id: UUID | None = None


class StudyQuestionResponseUpdate(BaseModel):
    response: str


class StudyQuestionResponseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    question_id: UUID
    parent_response_id: UUID | None
    group_id: UUID
    user_sub: str
    response: str
    created_at: datetime
    updated_at: datetime
