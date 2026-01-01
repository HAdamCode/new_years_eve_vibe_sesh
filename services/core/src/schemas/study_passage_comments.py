from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class StudyPassageCommentCreate(BaseModel):
    comment: str


class StudyPassageCommentUpdate(BaseModel):
    comment: str


class StudyPassageCommentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    passage_id: UUID
    group_id: UUID
    user_sub: str
    comment: str
    created_at: datetime
    updated_at: datetime
