import secrets
from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.group import Group
from models.group_member import GroupMember, GroupRole
from models.invite_code import InviteCode


def generate_invite_code() -> str:
    """Generate a unique, URL-safe invite code."""
    return secrets.token_urlsafe(16)


def create_invite(
    db: Session,
    group_id: UUID,
    user_sub: str,
    expires_in_days: int | None = None,
) -> InviteCode:
    """Create an invite code for a group. Only leaders can create invites."""
    # Verify user is a leader of this group
    member = db.scalar(
        select(GroupMember).where(
            GroupMember.group_id == group_id,
            GroupMember.user_sub == user_sub,
            GroupMember.role == GroupRole.LEADER,
        )
    )
    if not member:
        raise ValueError("not_leader")

    # Generate unique code
    code = generate_invite_code()

    # Calculate expiration
    expires_at = None
    if expires_in_days:
        expires_at = datetime.now(timezone.utc) + timedelta(days=expires_in_days)

    invite = InviteCode(
        code=code,
        group_id=group_id,
        created_by=user_sub,
        expires_at=expires_at,
        is_active=True,
    )
    db.add(invite)
    db.commit()
    db.refresh(invite)
    return invite


def get_invite_by_code(db: Session, code: str) -> InviteCode | None:
    """Get an invite code by its code string."""
    return db.scalar(select(InviteCode).where(InviteCode.code == code))


def get_group_invites(db: Session, group_id: UUID) -> list[InviteCode]:
    """Get all active invites for a group."""
    return list(
        db.scalars(
            select(InviteCode)
            .where(InviteCode.group_id == group_id, InviteCode.is_active == True)
            .order_by(InviteCode.created_at.desc())
        )
    )


def join_by_invite(db: Session, code: str, user_sub: str) -> GroupMember:
    """Join a group using an invite code."""
    invite = get_invite_by_code(db, code)
    if not invite:
        raise ValueError("invite_not_found")

    if not invite.is_active:
        raise ValueError("invite_inactive")

    if invite.expires_at and invite.expires_at < datetime.now(timezone.utc):
        raise ValueError("invite_expired")

    # Check if already a member
    existing = db.scalar(
        select(GroupMember).where(
            GroupMember.group_id == invite.group_id,
            GroupMember.user_sub == user_sub,
        )
    )
    if existing:
        return existing

    # Add as member
    member = GroupMember(
        group_id=invite.group_id,
        user_sub=user_sub,
        role=GroupRole.MEMBER,
    )
    db.add(member)
    db.commit()
    db.refresh(member)
    return member


def deactivate_invite(db: Session, code: str, user_sub: str) -> None:
    """Deactivate an invite code. Only the creator or a leader can do this."""
    invite = get_invite_by_code(db, code)
    if not invite:
        raise ValueError("invite_not_found")

    # Check if user is creator or leader
    is_creator = invite.created_by == user_sub
    is_leader = db.scalar(
        select(GroupMember).where(
            GroupMember.group_id == invite.group_id,
            GroupMember.user_sub == user_sub,
            GroupMember.role == GroupRole.LEADER,
        )
    )

    if not is_creator and not is_leader:
        raise ValueError("not_authorized")

    invite.is_active = False
    db.commit()


def get_group_for_invite(db: Session, code: str) -> Group | None:
    """Get the group associated with an invite code."""
    invite = get_invite_by_code(db, code)
    if not invite:
        return None
    return db.get(Group, invite.group_id)
