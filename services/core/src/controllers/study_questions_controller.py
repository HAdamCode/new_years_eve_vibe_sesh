from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from models.group_member import GroupMember
from models.study import Study
from models.study_question import StudyQuestion
from models.study_question_response import StudyQuestionResponse
from models.study_session import StudySession
from schemas.study_question_responses import (
    StudyQuestionResponseCreate,
    StudyQuestionResponseOut,
    StudyQuestionResponseUpdate,
)
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


def _get_group_for_question(db: Session, question_id: UUID) -> UUID | None:
    question = db.get(StudyQuestion, question_id)
    if not question:
        return None
    session = db.get(StudySession, question.session_id)
    if not session:
        return None
    study = db.get(Study, session.study_id)
    if not study:
        return None
    return study.group_id


def _is_group_member(db: Session, group_id: UUID, user_sub: str) -> bool:
    membership = db.scalar(
        select(GroupMember).where(
            GroupMember.group_id == group_id,
            GroupMember.user_sub == user_sub,
        )
    )
    return membership is not None


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


@router.get("/{question_id}/responses", response_model=list[StudyQuestionResponseOut])
def get_responses(
    session_id: UUID,
    question_id: UUID,
    group_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyQuestionResponseOut]:
    return list(
        db.scalars(
            select(StudyQuestionResponse).where(
                StudyQuestionResponse.question_id == question_id,
                StudyQuestionResponse.group_id == group_id,
            )
        )
    )


@router.post(
    "/{question_id}/responses",
    response_model=StudyQuestionResponseOut,
    status_code=status.HTTP_201_CREATED,
)
def post_response(
    session_id: UUID,
    question_id: UUID,
    payload: StudyQuestionResponseCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyQuestionResponseOut:
    user_sub = _get_user_sub(claims)
    group_id = _get_group_for_question(db, question_id)
    if not group_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Question not found",
        )

    if not _is_group_member(db, group_id, user_sub):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only group members can respond",
        )

    item = StudyQuestionResponse(
        question_id=question_id,
        group_id=group_id,
        user_sub=user_sub,
        response=payload.response,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.patch("/{question_id}/responses/{response_id}", response_model=StudyQuestionResponseOut)
def patch_response(
    session_id: UUID,
    question_id: UUID,
    response_id: UUID,
    payload: StudyQuestionResponseUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyQuestionResponseOut:
    user_sub = _get_user_sub(claims)
    item = db.get(StudyQuestionResponse, response_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Response not found",
        )

    if item.user_sub != user_sub:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the author can update this response",
        )

    item.response = payload.response
    db.commit()
    db.refresh(item)
    return item


@router.delete("/{question_id}/responses/{response_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_response_route(
    session_id: UUID,
    question_id: UUID,
    response_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    item = db.get(StudyQuestionResponse, response_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Response not found",
        )

    if item.user_sub != user_sub:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the author can delete this response",
        )

    db.delete(item)
    db.commit()
    return None
