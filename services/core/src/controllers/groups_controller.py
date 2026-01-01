from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from schemas.groups import GroupCreate, GroupMemberOut, GroupOut
from services.groups_service import create_group, join_group, leave_group, list_groups

router = APIRouter(prefix="/groups", tags=["groups"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


@router.get("", response_model=list[GroupOut])
def get_groups(
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[GroupOut]:
    user_sub = _get_user_sub(claims)
    return list_groups(db, user_sub)


@router.get("/me", response_model=list[GroupOut])
def get_my_groups(
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[GroupOut]:
    user_sub = _get_user_sub(claims)
    return list_groups(db, user_sub)


@router.post("", response_model=GroupOut, status_code=status.HTTP_201_CREATED)
def post_group(
    payload: GroupCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> GroupOut:
    user_sub = _get_user_sub(claims)
    try:
        return create_group(db, payload.name, payload.description, user_sub)
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        ) from e


@router.post("/{group_id}/join", response_model=GroupMemberOut)
def post_join_group(
    group_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> GroupMemberOut:
    user_sub = _get_user_sub(claims)
    try:
        return join_group(db, group_id, user_sub)
    except ValueError as exc:
        if str(exc) == "group_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Group not found",
            ) from exc
        raise


@router.post("/{group_id}/leave", status_code=status.HTTP_204_NO_CONTENT)
def post_leave_group(
    group_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    try:
        leave_group(db, group_id, user_sub)
    except ValueError as exc:
        if str(exc) == "membership_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Membership not found",
            ) from exc
        raise
    return None
