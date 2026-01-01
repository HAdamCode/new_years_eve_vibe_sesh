from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from schemas.study_passages import StudyPassageCreate, StudyPassageOut
from services.study_passages_service import create_passage, delete_passage, list_passages

router = APIRouter(prefix="/sessions/{session_id}/passages", tags=["passages"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


@router.get("", response_model=list[StudyPassageOut])
def get_passages(
    session_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyPassageOut]:
    return list_passages(db, session_id)


@router.post("", response_model=StudyPassageOut, status_code=status.HTTP_201_CREATED)
def post_passage(
    session_id: UUID,
    payload: StudyPassageCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyPassageOut:
    user_sub = _get_user_sub(claims)
    try:
        return create_passage(
            db,
            session_id,
            user_sub,
            payload.book,
            payload.chapter,
            payload.start_verse,
            payload.end_verse,
            payload.version,
            payload.text,
        )
    except ValueError as exc:
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can add passages",
            ) from exc
        raise


@router.delete("/{passage_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_passage_route(
    session_id: UUID,
    passage_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    try:
        delete_passage(db, passage_id, user_sub)
    except ValueError as exc:
        if str(exc) == "passage_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Passage not found",
            ) from exc
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can delete passages",
            ) from exc
        raise
    return None
