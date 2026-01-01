from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.group_member import GroupMember
from models.study_question import StudyQuestion
from models.study_question_response import StudyQuestionResponse
from models.study_session import StudySession
from models.study import Study


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


def list_responses(db: Session, question_id: UUID, group_id: UUID) -> list[StudyQuestionResponse]:
    return list(
        db.scalars(
            select(StudyQuestionResponse).where(
                StudyQuestionResponse.question_id == question_id,
                StudyQuestionResponse.group_id == group_id,
            )
        )
    )


def create_response(
    db: Session,
    question_id: UUID,
    user_sub: str,
    response: str,
) -> StudyQuestionResponse:
    group_id = _get_group_for_question(db, question_id)
    if not group_id:
        raise ValueError("question_not_found")

    if not _is_group_member(db, group_id, user_sub):
        raise ValueError("forbidden")

    item = StudyQuestionResponse(
        question_id=question_id,
        group_id=group_id,
        user_sub=user_sub,
        response=response,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def update_response(
    db: Session,
    response_id: UUID,
    user_sub: str,
    response: str,
) -> StudyQuestionResponse:
    item = db.get(StudyQuestionResponse, response_id)
    if not item:
        raise ValueError("response_not_found")

    if item.user_sub != user_sub:
        raise ValueError("forbidden")

    item.response = response
    db.commit()
    db.refresh(item)
    return item


def delete_response(db: Session, response_id: UUID, user_sub: str) -> None:
    item = db.get(StudyQuestionResponse, response_id)
    if not item:
        raise ValueError("response_not_found")

    if item.user_sub != user_sub:
        raise ValueError("forbidden")

    db.delete(item)
    db.commit()
