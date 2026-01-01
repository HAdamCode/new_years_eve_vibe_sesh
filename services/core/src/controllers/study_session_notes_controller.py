from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from models.group_member import GroupMember
from models.group_session import GroupSession
from models.group_study import GroupStudy
from models.study_session import StudySession
from models.study_session_note import StudySessionNote
from schemas.study_session_notes import (
    StudySessionNoteCreate,
    StudySessionNoteOut,
    StudySessionNoteUpdate,
)

router = APIRouter(prefix="/sessions/{session_id}/notes", tags=["session-notes"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


def _ensure_group_session(db: Session, group_id: UUID, session_id: UUID) -> GroupSession:
    session = db.get(StudySession, session_id)
    if not session:
        raise ValueError("session_not_found")

    group_study = db.scalar(
        select(GroupStudy).where(
            GroupStudy.group_id == group_id,
            GroupStudy.study_id == session.study_id,
        )
    )
    if not group_study:
        group_study = GroupStudy(group_id=group_id, study_id=session.study_id)
        db.add(group_study)
        db.flush()

    group_session = db.scalar(
        select(GroupSession).where(
            GroupSession.group_study_id == group_study.id,
            GroupSession.study_session_id == session_id,
        )
    )
    if not group_session:
        group_session = GroupSession(
            group_study_id=group_study.id,
            study_session_id=session_id,
        )
        db.add(group_session)
        db.flush()

    return group_session


def _is_group_member(db: Session, group_id: UUID, user_sub: str) -> bool:
    membership = db.scalar(
        select(GroupMember).where(
            GroupMember.group_id == group_id,
            GroupMember.user_sub == user_sub,
        )
    )
    return membership is not None


@router.get("", response_model=list[StudySessionNoteOut])
def get_notes(
    session_id: UUID,
    group_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudySessionNoteOut]:
    return list(
        db.scalars(
            select(StudySessionNote).where(
                StudySessionNote.session_id == session_id,
                StudySessionNote.group_id == group_id,
            )
        )
    )


@router.post("", response_model=StudySessionNoteOut, status_code=status.HTTP_201_CREATED)
def post_note(
    session_id: UUID,
    group_id: UUID,
    payload: StudySessionNoteCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudySessionNoteOut:
    user_sub = _get_user_sub(claims)
    if not _is_group_member(db, group_id, user_sub):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only group members can add notes",
        )

    try:
        group_session = _ensure_group_session(db, group_id, session_id)
    except ValueError as exc:
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        raise
    item = StudySessionNote(
        session_id=session_id,
        group_session_id=group_session.id,
        group_id=group_id,
        user_sub=user_sub,
        note=payload.note,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.patch("/{note_id}", response_model=StudySessionNoteOut)
def patch_note(
    session_id: UUID,
    note_id: UUID,
    payload: StudySessionNoteUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudySessionNoteOut:
    user_sub = _get_user_sub(claims)
    item = db.get(StudySessionNote, note_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Note not found",
        )

    if item.user_sub != user_sub:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the author can update this note",
        )

    item.note = payload.note
    db.commit()
    db.refresh(item)
    return item


@router.delete("/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_note_route(
    session_id: UUID,
    note_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    item = db.get(StudySessionNote, note_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Note not found",
        )

    if item.user_sub != user_sub:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the author can delete this note",
        )

    db.delete(item)
    db.commit()
    return None
