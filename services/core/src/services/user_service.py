from sqlalchemy.orm import Session

from models.user import User


def get_user_by_cognito_sub(db: Session, cognito_sub: str) -> User | None:
    """Get user by Cognito sub (subject identifier)."""
    return db.query(User).filter(User.cognito_sub == cognito_sub).first()


def create_user(db: Session, cognito_sub: str, display_name: str) -> User:
    """Create a new user profile."""
    user = User(cognito_sub=cognito_sub, display_name=display_name)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def get_or_create_user(db: Session, cognito_sub: str, default_name: str = "User") -> User:
    """Get existing user or create with default name."""
    user = get_user_by_cognito_sub(db, cognito_sub)
    if user is None:
        user = create_user(db, cognito_sub, default_name)
    return user


def update_user(db: Session, cognito_sub: str, display_name: str) -> User | None:
    """Update user's display name."""
    user = get_user_by_cognito_sub(db, cognito_sub)
    if user is None:
        return None
    user.display_name = display_name
    db.commit()
    db.refresh(user)
    return user
