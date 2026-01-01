from uuid import UUID

from pydantic import BaseModel, Field, computed_field


class UserCreate(BaseModel):
    """Schema for creating a new user profile."""

    display_name: str = Field(..., min_length=1, max_length=100)


class UserUpdate(BaseModel):
    """Schema for updating user profile."""

    display_name: str = Field(..., min_length=1, max_length=100)


class UserResponse(BaseModel):
    """Schema for user profile response."""

    id: UUID
    display_name: str

    @computed_field
    @property
    def initials(self) -> str:
        """Compute initials from display name."""
        parts = self.display_name.strip().split()
        if len(parts) >= 2:
            return (parts[0][0] + parts[-1][0]).upper()
        elif parts:
            return parts[0][0].upper()
        return ""

    class Config:
        from_attributes = True
