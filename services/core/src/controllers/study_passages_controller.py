from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from models.group_member import GroupMember
from models.group_session import GroupSession
from models.group_study import GroupStudy
from models.study import Study
from models.study_passage import StudyPassage
from models.study_passage_comment import StudyPassageComment
from models.study_passage_like import StudyPassageLike
from models.study_session import StudySession
from schemas.study_passage_comments import (
    StudyPassageCommentCreate,
    StudyPassageCommentOut,
    StudyPassageCommentUpdate,
)
from schemas.study_passage_likes import StudyPassageLikeOut
from schemas.study_passages import StudyPassageCreate, StudyPassageOut, StudyPassageUpdate
from services.study_passages_service import (
    create_passage,
    delete_passage,
    list_passages,
    update_passage,
)

router = APIRouter(prefix="/sessions/{session_id}/passages", tags=["passages"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


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


@router.get("", response_model=list[StudyPassageOut])
def get_passages(
    session_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyPassageOut]:
    return list_passages(db, session_id)


@router.post("", response_model=StudyPassageOut, status_code=status.HTTP_201_CREATED)
def post_passage(
    session_id: UUID,
    payload: StudyPassageCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyPassageOut:
    user_sub = _get_user_sub(claims)
    try:
        return create_passage(
            db,
            session_id,
            user_sub,
            payload.book,
            payload.chapter,
            payload.start_verse,
            payload.end_verse,
            payload.version,
            payload.text,
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
                detail="Only leaders can add passages",
            ) from exc
        raise


@router.delete("/{passage_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_passage_route(
    session_id: UUID,
    passage_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    try:
        delete_passage(db, passage_id, user_sub)
    except ValueError as exc:
        if str(exc) == "passage_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Passage not found",
            ) from exc
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can delete passages",
            ) from exc
        raise
    return None


@router.patch("/{passage_id}", response_model=StudyPassageOut)
def patch_passage(
    session_id: UUID,
    passage_id: UUID,
    payload: StudyPassageUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyPassageOut:
    user_sub = _get_user_sub(claims)
    try:
        return update_passage(
            db,
            passage_id,
            user_sub,
            payload.book,
            payload.chapter,
            payload.start_verse,
            payload.end_verse,
            payload.version,
            payload.text,
        )
    except ValueError as exc:
        if str(exc) == "passage_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Passage not found",
            ) from exc
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can update passages",
            ) from exc
        raise


@router.get("/{passage_id}/likes", response_model=list[StudyPassageLikeOut])
def get_likes(
    session_id: UUID,
    passage_id: UUID,
    group_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyPassageLikeOut]:
    return list(
        db.scalars(
            select(StudyPassageLike).where(
                StudyPassageLike.passage_id == passage_id,
                StudyPassageLike.group_id == group_id,
            )
        )
    )


@router.post("/{passage_id}/likes", response_model=StudyPassageLikeOut, status_code=status.HTTP_201_CREATED)
def post_like(
    session_id: UUID,
    passage_id: UUID,
    group_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyPassageLikeOut:
    user_sub = _get_user_sub(claims)
    passage = db.get(StudyPassage, passage_id)
    if not passage:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Passage not found",
        )

    if not _is_group_member(db, group_id, user_sub):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only group members can like passages",
        )

    existing = db.scalar(
        select(StudyPassageLike).where(
            StudyPassageLike.passage_id == passage_id,
            StudyPassageLike.group_id == group_id,
            StudyPassageLike.user_sub == user_sub,
        )
    )
    if existing:
        return existing

    try:
        group_session = _ensure_group_session(db, group_id, session_id)
    except ValueError as exc:
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        raise

    item = StudyPassageLike(
        passage_id=passage_id,
        group_id=group_id,
        group_session_id=group_session.id,
        user_sub=user_sub,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.delete("/{passage_id}/likes/{like_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_like_route(
    session_id: UUID,
    passage_id: UUID,
    like_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    item = db.get(StudyPassageLike, like_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Like not found",
        )

    if item.user_sub != user_sub:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the author can remove this like",
        )

    db.delete(item)
    db.commit()
    return None


@router.get("/{passage_id}/comments", response_model=list[StudyPassageCommentOut])
def get_comments(
    session_id: UUID,
    passage_id: UUID,
    group_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyPassageCommentOut]:
    return list(
        db.scalars(
            select(StudyPassageComment).where(
                StudyPassageComment.passage_id == passage_id,
                StudyPassageComment.group_id == group_id,
            )
        )
    )


@router.post("/{passage_id}/comments", response_model=StudyPassageCommentOut, status_code=status.HTTP_201_CREATED)
def post_comment(
    session_id: UUID,
    passage_id: UUID,
    group_id: UUID,
    payload: StudyPassageCommentCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyPassageCommentOut:
    user_sub = _get_user_sub(claims)
    passage = db.get(StudyPassage, passage_id)
    if not passage:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Passage not found",
        )

    if not _is_group_member(db, group_id, user_sub):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only group members can comment",
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

    item = StudyPassageComment(
        passage_id=passage_id,
        group_id=group_id,
        group_session_id=group_session.id,
        user_sub=user_sub,
        comment=payload.comment,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.patch("/{passage_id}/comments/{comment_id}", response_model=StudyPassageCommentOut)
def patch_comment(
    session_id: UUID,
    passage_id: UUID,
    comment_id: UUID,
    payload: StudyPassageCommentUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyPassageCommentOut:
    user_sub = _get_user_sub(claims)
    item = db.get(StudyPassageComment, comment_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found",
        )

    if item.user_sub != user_sub:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the author can update this comment",
        )

    item.comment = payload.comment
    db.commit()
    db.refresh(item)
    return item


@router.delete("/{passage_id}/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_comment_route(
    session_id: UUID,
    passage_id: UUID,
    comment_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    item = db.get(StudyPassageComment, comment_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found",
        )

    if item.user_sub != user_sub:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the author can delete this comment",
        )

    db.delete(item)
    db.commit()
    return None
