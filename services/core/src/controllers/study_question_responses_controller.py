from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from schemas.study_question_responses import (
    StudyQuestionResponseCreate,
    StudyQuestionResponseOut,
    StudyQuestionResponseUpdate,
)
from services.study_question_responses_service import (
    create_response,
    delete_response,
    list_responses,
    update_response,
)

router = APIRouter(prefix="/questions/{question_id}/responses", tags=["responses"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


@router.get("", response_model=list[StudyQuestionResponseOut])
def get_responses(
    question_id: UUID,
    group_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyQuestionResponseOut]:
    return list_responses(db, question_id, group_id)


@router.post("", response_model=StudyQuestionResponseOut, status_code=status.HTTP_201_CREATED)
def post_response(
    question_id: UUID,
    payload: StudyQuestionResponseCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyQuestionResponseOut:
    user_sub = _get_user_sub(claims)
    try:
        return create_response(db, question_id, user_sub, payload.response)
    except ValueError as exc:
        if str(exc) == "question_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Question not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only group members can respond",
            ) from exc
        raise


@router.patch("/{response_id}", response_model=StudyQuestionResponseOut)
def patch_response(
    question_id: UUID,
    response_id: UUID,
    payload: StudyQuestionResponseUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyQuestionResponseOut:
    user_sub = _get_user_sub(claims)
    try:
        return update_response(db, response_id, user_sub, payload.response)
    except ValueError as exc:
        if str(exc) == "response_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Response not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the author can update this response",
            ) from exc
        raise


@router.delete("/{response_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_response_route(
    question_id: UUID,
    response_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    try:
        delete_response(db, response_id, user_sub)
    except ValueError as exc:
        if str(exc) == "response_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Response not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the author can delete this response",
            ) from exc
        raise
    return None
