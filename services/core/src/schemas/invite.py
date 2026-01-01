from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class InviteCodeCreate(BaseModel):
    expires_in_days: int | None = None  # None means no expiration


class InviteCodeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    group_id: UUID
    created_at: datetime
    expires_at: datetime | None
    is_active: bool


class InviteLinkOut(BaseModel):
    code: str
    link: str
    group_id: UUID
    group_name: str


class JoinByInviteRequest(BaseModel):
    code: str
