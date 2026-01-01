from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class StudyPassageLikeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    passage_id: UUID
    group_id: UUID
    user_sub: str
    created_at: datetime
