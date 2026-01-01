from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.cognito import cognito_auth_required
from db import get_db
from schemas.user import UserResponse, UserUpdate
from services.user_service import get_or_create_user, update_user

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=UserResponse)
def get_profile(
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> UserResponse:
    """Get current user's profile. Creates profile if it doesn't exist."""
    cognito_sub = str(claims.get("sub", ""))
    if not cognito_sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing sub",
        )

    user = get_or_create_user(db, cognito_sub)
    return UserResponse.model_validate(user)


@router.put("", response_model=UserResponse)
def update_profile(
    data: UserUpdate,
    claims: dict[str, object] = Depends(cognito_auth_required),
    db: Session = Depends(get_db),
) -> UserResponse:
    """Update current user's display name."""
    cognito_sub = str(claims.get("sub", ""))
    if not cognito_sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing sub",
        )

    user = update_user(db, cognito_sub, data.display_name)
    if user is None:
        # User doesn't exist, create with the provided name
        user = get_or_create_user(db, cognito_sub, data.display_name)

    return UserResponse.model_validate(user)
