from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from models.group_member import GroupMember, GroupRole
from models.study import Study


def _is_group_leader(db: Session, group_id: UUID, user_sub: str) -> bool:
    membership = db.scalar(
        select(GroupMember).where(
            GroupMember.group_id == group_id,
            GroupMember.user_sub == user_sub,
            GroupMember.role == GroupRole.LEADER,
        )
    )
    return membership is not None


def list_studies(db: Session, group_id: UUID) -> list[Study]:
    return list(db.scalars(select(Study).where(Study.group_id == group_id)))


def create_study(
    db: Session,
    group_id: UUID,
    title: str,
    description: str | None,
    user_sub: str,
) -> Study:
    if not _is_group_leader(db, group_id, user_sub):
        raise ValueError("forbidden")

    study = Study(group_id=group_id, title=title, description=description)
    db.add(study)
    db.commit()
    db.refresh(study)
    return study


def update_study(
    db: Session,
    study_id: UUID,
    user_sub: str,
    title: str | None,
    description: str | None,
    is_archived: bool | None,
) -> Study:
    study = db.get(Study, study_id)
    if not study:
        raise ValueError("study_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    if title is not None:
        study.title = title
    if description is not None:
        study.description = description
    if is_archived is not None:
        study.is_archived = is_archived

    db.commit()
    db.refresh(study)
    return study


def delete_study(db: Session, study_id: UUID, user_sub: str) -> None:
    study = db.get(Study, study_id)
    if not study:
        raise ValueError("study_not_found")

    if not _is_group_leader(db, study.group_id, user_sub):
        raise ValueError("forbidden")

    db.delete(study)
    db.commit()
