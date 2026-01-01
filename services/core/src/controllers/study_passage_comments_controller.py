from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from schemas.study_passage_comments import (
    StudyPassageCommentCreate,
    StudyPassageCommentOut,
    StudyPassageCommentUpdate,
)
from services.study_passage_comments_service import (
    create_comment,
    delete_comment,
    list_comments,
    update_comment,
)

router = APIRouter(prefix="/passages/{passage_id}/comments", tags=["passage-comments"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


@router.get("", response_model=list[StudyPassageCommentOut])
def get_comments(
    passage_id: UUID,
    group_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyPassageCommentOut]:
    return list_comments(db, passage_id, group_id)


@router.post("", response_model=StudyPassageCommentOut, status_code=status.HTTP_201_CREATED)
def post_comment(
    passage_id: UUID,
    payload: StudyPassageCommentCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyPassageCommentOut:
    user_sub = _get_user_sub(claims)
    try:
        return create_comment(db, passage_id, user_sub, payload.comment)
    except ValueError as exc:
        if str(exc) == "passage_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Passage not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only group members can comment",
            ) from exc
        raise


@router.patch("/{comment_id}", response_model=StudyPassageCommentOut)
def patch_comment(
    passage_id: UUID,
    comment_id: UUID,
    payload: StudyPassageCommentUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyPassageCommentOut:
    user_sub = _get_user_sub(claims)
    try:
        return update_comment(db, comment_id, user_sub, payload.comment)
    except ValueError as exc:
        if str(exc) == "comment_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the author can update this comment",
            ) from exc
        raise


@router.delete("/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_comment_route(
    passage_id: UUID,
    comment_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    try:
        delete_comment(db, comment_id, user_sub)
    except ValueError as exc:
        if str(exc) == "comment_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the author can delete this comment",
            ) from exc
        raise
    return None
