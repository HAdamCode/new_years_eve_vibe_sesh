from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.group_member import GroupMember, GroupRole
from models.study import Study
from models.study_passage import StudyPassage
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


def list_passages(db: Session, session_id: UUID) -> list[StudyPassage]:
    return list(
        db.scalars(
            select(StudyPassage).where(StudyPassage.session_id == session_id)
        )
    )


def create_passage(
    db: Session,
    session_id: UUID,
    user_sub: str,
    book: str,
    chapter: int,
    start_verse: int | None,
    end_verse: int | None,
    version: str | None,
    text: str | None,
) -> StudyPassage:
    study = _get_study_for_session(db, session_id)
    if not study:
        raise ValueError("session_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    passage = StudyPassage(
        session_id=session_id,
        book=book,
        chapter=chapter,
        start_verse=start_verse,
        end_verse=end_verse,
        version=version,
        text=text,
    )
    db.add(passage)
    db.commit()
    db.refresh(passage)
    return passage


def delete_passage(db: Session, passage_id: UUID, user_sub: str) -> None:
    passage = db.get(StudyPassage, passage_id)
    if not passage:
        raise ValueError("passage_not_found")

    study = _get_study_for_session(db, passage.session_id)
    if not study:
        raise ValueError("session_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    db.delete(passage)
    db.commit()
