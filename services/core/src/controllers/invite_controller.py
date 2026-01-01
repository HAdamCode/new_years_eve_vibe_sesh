import os
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from models.group import Group
from schemas.groups import GroupMemberOut, GroupOut
from schemas.invite import InviteCodeCreate, InviteCodeOut, InviteLinkOut, JoinByInviteRequest
from services.invite_service import (
    create_invite,
    deactivate_invite,
    get_group_for_invite,
    get_group_invites,
    join_by_invite,
)

router = APIRouter(prefix="/invites", tags=["invites"])

# Base URL for invite links - can be configured via environment variable
INVITE_BASE_URL = os.getenv("INVITE_BASE_URL", "nyevibe://join")


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


@router.post("/groups/{group_id}", response_model=InviteLinkOut)
def create_group_invite(
    group_id: UUID,
    payload: InviteCodeCreate | None = None,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> InviteLinkOut:
    """Create an invite link for a group. Only leaders can create invites."""
    user_sub = _get_user_sub(claims)
    expires_in_days = payload.expires_in_days if payload else None

    try:
        invite = create_invite(db, group_id, user_sub, expires_in_days)
    except ValueError as exc:
        if str(exc) == "not_leader":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only group leaders can create invite links",
            ) from exc
        raise

    # Get group name for the response
    group = db.get(Group, group_id)
    group_name = group.name if group else "Unknown Group"

    return InviteLinkOut(
        code=invite.code,
        link=f"{INVITE_BASE_URL}/{invite.code}",
        group_id=group_id,
        group_name=group_name,
    )


@router.get("/groups/{group_id}", response_model=list[InviteCodeOut])
def list_group_invites(
    group_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[InviteCodeOut]:
    """List all active invites for a group."""
    return get_group_invites(db, group_id)


@router.post("/join", response_model=GroupMemberOut)
def join_with_invite(
    payload: JoinByInviteRequest,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> GroupMemberOut:
    """Join a group using an invite code."""
    user_sub = _get_user_sub(claims)

    try:
        member = join_by_invite(db, payload.code, user_sub)
        return member
    except ValueError as exc:
        error = str(exc)
        if error == "invite_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invite code not found",
            ) from exc
        if error == "invite_inactive":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This invite link is no longer active",
            ) from exc
        if error == "invite_expired":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This invite link has expired",
            ) from exc
        raise


@router.get("/preview/{code}", response_model=GroupOut)
def preview_invite(
    code: str,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> GroupOut:
    """Get group info for an invite code before joining."""
    group = get_group_for_invite(db, code)
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invite code not found or expired",
        )
    return group


@router.delete("/{code}", status_code=status.HTTP_204_NO_CONTENT)
def revoke_invite(
    code: str,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    """Deactivate an invite code."""
    user_sub = _get_user_sub(claims)

    try:
        deactivate_invite(db, code, user_sub)
    except ValueError as exc:
        error = str(exc)
        if error == "invite_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invite code not found",
            ) from exc
        if error == "not_authorized":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to revoke this invite",
            ) from exc
        raise
