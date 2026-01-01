from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.group import Group
from models.group_member import GroupMember, GroupRole


def list_groups(db: Session) -> list[Group]:
    return list(db.scalars(select(Group).order_by(Group.created_at.desc())))


def create_group(db: Session, name: str, description: str | None, user_sub: str) -> Group:
    group = Group(name=name, description=description)
    db.add(group)
    db.flush()

    member = GroupMember(group_id=group.id, user_sub=user_sub, role=GroupRole.LEADER)
    db.add(member)
    db.commit()
    db.refresh(group)
    return group


def join_group(db: Session, group_id: UUID, user_sub: str) -> GroupMember:
    group = db.get(Group, group_id)
    if not group:
        raise ValueError("group_not_found")

    existing = db.scalar(
        select(GroupMember).where(
            GroupMember.group_id == group_id,
            GroupMember.user_sub == user_sub,
        )
    )
    if existing:
        return existing

    member = GroupMember(group_id=group_id, user_sub=user_sub, role=GroupRole.MEMBER)
    db.add(member)
    db.commit()
    db.refresh(member)
    return member


def leave_group(db: Session, group_id: UUID, user_sub: str) -> None:
    member = db.scalar(
        select(GroupMember).where(
            GroupMember.group_id == group_id,
            GroupMember.user_sub == user_sub,
        )
    )
    if not member:
        raise ValueError("membership_not_found")

    db.delete(member)
    db.commit()
