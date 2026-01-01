import enum
import uuid

from sqlalchemy import Column, DateTime, Enum, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from db import Base


class GroupRole(str, enum.Enum):
    MEMBER = "member"
    LEADER = "leader"


class GroupMember(Base):
    __tablename__ = "group_members"
    __table_args__ = (UniqueConstraint("group_id", "user_sub", name="uq_group_member"),)

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    group_id = Column(UUID(as_uuid=True), ForeignKey("groups.id", ondelete="CASCADE"), nullable=False)
    user_sub = Column(String(128), nullable=False)
    role = Column(Enum(GroupRole, name="group_role"), nullable=False, default=GroupRole.MEMBER)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
