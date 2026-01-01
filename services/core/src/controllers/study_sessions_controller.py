from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from schemas.study_sessions import (
    StudySessionCreate,
    StudySessionOut,
    StudySessionReorderItem,
    StudySessionUpdate,
)
from services.study_sessions_service import (
    create_session,
    delete_session,
    list_sessions,
    reorder_sessions,
    update_session,
)

router = APIRouter(prefix="/studies/{study_id}/sessions", tags=["sessions"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


@router.get("", response_model=list[StudySessionOut])
def get_sessions(
    study_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudySessionOut]:
    return list_sessions(db, study_id)


@router.post("", response_model=StudySessionOut, status_code=status.HTTP_201_CREATED)
def post_session(
    study_id: UUID,
    payload: StudySessionCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudySessionOut:
    user_sub = _get_user_sub(claims)
    try:
        return create_session(
            db,
            study_id,
            payload.title,
            payload.description,
            payload.position,
            user_sub,
        )
    except ValueError as exc:
        if str(exc) == "study_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Study not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can add sessions",
            ) from exc
        raise


@router.patch("/{session_id}", response_model=StudySessionOut)
def patch_session(
    study_id: UUID,
    session_id: UUID,
    payload: StudySessionUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudySessionOut:
    user_sub = _get_user_sub(claims)
    try:
        return update_session(
            db,
            session_id,
            user_sub,
            payload.title,
            payload.description,
            payload.position,
        )
    except ValueError as exc:
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        if str(exc) == "study_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Study not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can update sessions",
            ) from exc
        raise


@router.put("/reorder", response_model=list[StudySessionOut])
def put_reorder_sessions(
    study_id: UUID,
    payload: list[StudySessionReorderItem],
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudySessionOut]:
    user_sub = _get_user_sub(claims)
    try:
        updates = [(item.id, item.position) for item in payload]
        return reorder_sessions(db, study_id, user_sub, updates)
    except ValueError as exc:
        if str(exc) == "study_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Study not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can reorder sessions",
            ) from exc
        raise


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_session_route(
    study_id: UUID,
    session_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    try:
        delete_session(db, session_id, user_sub)
    except ValueError as exc:
        if str(exc) == "session_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found",
            ) from exc
        if str(exc) == "study_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Study not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can delete sessions",
            ) from exc
        raise
    return None
