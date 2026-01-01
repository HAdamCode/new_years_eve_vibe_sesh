from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from schemas.study_questions import (
    StudyQuestionCreate,
    StudyQuestionOut,
    StudyQuestionUpdate,
)
from services.study_questions_service import (
    create_question,
    delete_question,
    list_questions,
    update_question,
)

router = APIRouter(prefix="/sessions/{session_id}/questions", tags=["questions"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


@router.get("", response_model=list[StudyQuestionOut])
def get_questions(
    session_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyQuestionOut]:
    return list_questions(db, session_id)


@router.post("", response_model=StudyQuestionOut, status_code=status.HTTP_201_CREATED)
def post_question(
    session_id: UUID,
    payload: StudyQuestionCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyQuestionOut:
    user_sub = _get_user_sub(claims)
    try:
        return create_question(
            db,
            session_id,
            user_sub,
            payload.question,
            payload.position,
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
                detail="Only leaders can add questions",
            ) from exc
        raise


@router.delete("/{question_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_question_route(
    session_id: UUID,
    question_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    try:
        delete_question(db, question_id, user_sub)
    except ValueError as exc:
        if str(exc) == "question_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found",
            ) from exc
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can delete questions",
            ) from exc
        raise
    return None


@router.patch("/{question_id}", response_model=StudyQuestionOut)
def patch_question(
    session_id: UUID,
    question_id: UUID,
    payload: StudyQuestionUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyQuestionOut:
    user_sub = _get_user_sub(claims)
    try:
        return update_question(
            db,
            question_id,
            user_sub,
            payload.question,
            payload.position,
        )
    except ValueError as exc:
        if str(exc) == "question_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found",
            ) from exc
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can update questions",
            ) from exc
        raise
