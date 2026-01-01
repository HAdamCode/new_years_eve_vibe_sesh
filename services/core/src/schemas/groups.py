from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class GroupCreate(BaseModel):
    name: str
    description: str | None = None


class GroupOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str | None
    created_at: datetime


class GroupMemberOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    group_id: UUID
    user_sub: str
    role: str
    created_at: datetime
