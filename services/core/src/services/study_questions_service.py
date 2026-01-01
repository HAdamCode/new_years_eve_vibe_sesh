from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from models.group_member import GroupMember, GroupRole
from models.study import Study
from models.study_question import StudyQuestion
from models.study_session import StudySession


def _is_group_leader(db: Session, group_id: UUID, user_sub: str) -> bool:
    membership = db.scalar(
        select(GroupMember).where(
            GroupMember.group_id == group_id,
            GroupMember.user_sub == user_sub,
            GroupMember.role == GroupRole.LEADER,
        )
    )
    return membership is not None


def _get_study_for_session(db: Session, session_id: UUID) -> Study | None:
    session = db.get(StudySession, session_id)
    if not session:
        return None
    return db.get(Study, session.study_id)


def list_questions(db: Session, session_id: UUID) -> list[StudyQuestion]:
    return list(
        db.scalars(
            select(StudyQuestion)
            .where(StudyQuestion.session_id == session_id)
            .order_by(StudyQuestion.position.asc(), StudyQuestion.created_at.asc())
        )
    )


def create_question(
    db: Session,
    session_id: UUID,
    user_sub: str,
    question: str,
    position: int | None,
) -> StudyQuestion:
    study = _get_study_for_session(db, session_id)
    if not study:
        raise ValueError("session_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    if position is None:
        position = (
            db.scalar(
                select(func.coalesce(func.max(StudyQuestion.position), 0)).where(
                    StudyQuestion.session_id == session_id
                )
            )
            or 0
        ) + 1

    item = StudyQuestion(session_id=session_id, question=question, position=position)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def delete_question(db: Session, question_id: UUID, user_sub: str) -> None:
    item = db.get(StudyQuestion, question_id)
    if not item:
        raise ValueError("question_not_found")

    study = _get_study_for_session(db, item.session_id)
    if not study:
        raise ValueError("session_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    db.delete(item)
    db.commit()
