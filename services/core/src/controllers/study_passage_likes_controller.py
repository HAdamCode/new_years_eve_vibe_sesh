from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from schemas.study_passage_likes import StudyPassageLikeOut
from services.study_passage_likes_service import create_like, delete_like, list_likes

router = APIRouter(prefix="/passages/{passage_id}/likes", tags=["passage-likes"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


@router.get("", response_model=list[StudyPassageLikeOut])
def get_likes(
    passage_id: UUID,
    group_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyPassageLikeOut]:
    return list_likes(db, passage_id, group_id)


@router.post("", response_model=StudyPassageLikeOut, status_code=status.HTTP_201_CREATED)
def post_like(
    passage_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyPassageLikeOut:
    user_sub = _get_user_sub(claims)
    try:
        return create_like(db, passage_id, user_sub)
    except ValueError as exc:
        if str(exc) == "passage_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Passage not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only group members can like passages",
            ) from exc
        raise


@router.delete("/{like_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_like_route(
    passage_id: UUID,
    like_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    try:
        delete_like(db, like_id, user_sub)
    except ValueError as exc:
        if str(exc) == "like_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Like not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the author can remove this like",
            ) from exc
        raise
    return None
