from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.group_member import GroupMember
from models.study import Study
from models.study_passage import StudyPassage
from models.study_passage_like import StudyPassageLike
from models.study_session import StudySession


def _get_group_for_passage(db: Session, passage_id: UUID) -> UUID | None:
    passage = db.get(StudyPassage, passage_id)
    if not passage:
        return None
    session = db.get(StudySession, passage.session_id)
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


def list_likes(db: Session, passage_id: UUID, group_id: UUID) -> list[StudyPassageLike]:
    return list(
        db.scalars(
            select(StudyPassageLike).where(
                StudyPassageLike.passage_id == passage_id,
                StudyPassageLike.group_id == group_id,
            )
        )
    )


def create_like(db: Session, passage_id: UUID, user_sub: str) -> StudyPassageLike:
    group_id = _get_group_for_passage(db, passage_id)
    if not group_id:
        raise ValueError("passage_not_found")

    if not _is_group_member(db, group_id, user_sub):
        raise ValueError("forbidden")

    existing = db.scalar(
        select(StudyPassageLike).where(
            StudyPassageLike.passage_id == passage_id,
            StudyPassageLike.group_id == group_id,
            StudyPassageLike.user_sub == user_sub,
        )
    )
    if existing:
        return existing

    item = StudyPassageLike(
        passage_id=passage_id,
        group_id=group_id,
        user_sub=user_sub,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


def delete_like(db: Session, like_id: UUID, user_sub: str) -> None:
    item = db.get(StudyPassageLike, like_id)
    if not item:
        raise ValueError("like_not_found")

    if item.user_sub != user_sub:
        raise ValueError("forbidden")

    db.delete(item)
    db.commit()
