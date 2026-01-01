"""add users table

Revision ID: 001
Revises:
Create Date: 2024-12-31

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "001"
down_revision: str | None = "202501011200"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("cognito_sub", sa.String(), nullable=False),
        sa.Column("display_name", sa.String(100), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_cognito_sub", "users", ["cognito_sub"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_users_cognito_sub", table_name="users")
    op.drop_table("users")
