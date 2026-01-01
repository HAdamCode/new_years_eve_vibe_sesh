from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from schemas.studies import StudyCreate, StudyOut, StudyUpdate
from services.studies_service import create_study, delete_study, list_studies, update_study

router = APIRouter(prefix="/groups/{group_id}/studies", tags=["studies"])


def _get_user_sub(claims: dict[str, object]) -> str:
    user_sub = claims.get("sub")
    if not isinstance(user_sub, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing user sub",
        )
    return user_sub


@router.get("", response_model=list[StudyOut])
def get_studies(
    group_id: UUID,
    _claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> list[StudyOut]:
    return list_studies(db, group_id)


@router.post("", response_model=StudyOut, status_code=status.HTTP_201_CREATED)
def post_study(
    group_id: UUID,
    payload: StudyCreate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyOut:
    user_sub = _get_user_sub(claims)
    try:
        return create_study(db, group_id, payload.title, payload.description, user_sub)
    except ValueError as exc:
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can create studies",
            ) from exc
        raise


@router.patch("/{study_id}", response_model=StudyOut)
def patch_study(
    group_id: UUID,
    study_id: UUID,
    payload: StudyUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> StudyOut:
    user_sub = _get_user_sub(claims)
    try:
        return update_study(
            db,
            study_id,
            user_sub,
            payload.title,
            payload.description,
            payload.is_archived,
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
                detail="Only leaders can update studies",
            ) from exc
        raise


@router.delete("/{study_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_study_route(
    group_id: UUID,
    study_id: UUID,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> None:
    user_sub = _get_user_sub(claims)
    try:
        delete_study(db, study_id, user_sub)
    except ValueError as exc:
        if str(exc) == "study_not_found":
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Study not found",
            ) from exc
        if str(exc) == "forbidden":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only leaders can delete studies",
            ) from exc
        raise
    return None
