from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.orm import Session

from models.group_member import GroupMember, GroupRole
from models.study import Study
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


def _get_study(db: Session, study_id: UUID) -> Study | None:
    return db.get(Study, study_id)


def list_sessions(db: Session, study_id: UUID) -> list[StudySession]:
    return list(
        db.scalars(
            select(StudySession)
            .where(StudySession.study_id == study_id)
            .order_by(StudySession.position.asc(), StudySession.created_at.asc())
        )
    )


def create_session(
    db: Session,
    study_id: UUID,
    title: str,
    description: str | None,
    position: int | None,
    user_sub: str,
) -> StudySession:
    study = _get_study(db, study_id)
    if not study:
        raise ValueError("study_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    if position is None:
        position = (
            db.scalar(
                select(func.coalesce(func.max(StudySession.position), 0)).where(
                    StudySession.study_id == study_id
                )
            )
            or 0
        ) + 1

    session = StudySession(
        study_id=study_id,
        title=title,
        description=description,
        position=position,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def update_session(
    db: Session,
    session_id: UUID,
    user_sub: str,
    title: str | None,
    description: str | None,
    position: int | None,
) -> StudySession:
    session = db.get(StudySession, session_id)
    if not session:
        raise ValueError("session_not_found")

    study = _get_study(db, session.study_id)
    if not study:
        raise ValueError("study_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    if title is not None:
        session.title = title
    if description is not None:
        session.description = description
    if position is not None:
        session.position = position

    db.commit()
    db.refresh(session)
    return session


def reorder_sessions(
    db: Session,
    study_id: UUID,
    user_sub: str,
    updates: list[tuple[UUID, int]],
) -> list[StudySession]:
    study = _get_study(db, study_id)
    if not study:
        raise ValueError("study_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    sessions = list(
        db.scalars(select(StudySession).where(StudySession.study_id == study_id))
    )
    session_map = {session.id: session for session in sessions}

    for session_id, position in updates:
        if session_id in session_map:
            session_map[session_id].position = position

    db.commit()
    return list_sessions(db, study_id)


def delete_session(db: Session, session_id: UUID, user_sub: str) -> None:
    session = db.get(StudySession, session_id)
    if not session:
        raise ValueError("session_not_found")

    study = _get_study(db, session.study_id)
    if not study:
        raise ValueError("study_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    db.delete(session)
    db.commit()
