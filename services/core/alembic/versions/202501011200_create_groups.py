"""create groups and group_members

Revision ID: 202501011200
Revises: 
Create Date: 2025-01-01 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "202501011200"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create groups table
    op.create_table(
        "groups",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )

    # Create enum type for roles using raw SQL to avoid duplication issues
    op.execute("CREATE TYPE group_role AS ENUM ('member', 'leader')")

    # Create group_members table
    op.create_table(
        "group_members",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "group_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("user_sub", sa.String(length=128), nullable=False),
        sa.Column(
            "role",
            postgresql.ENUM("member", "leader", name="group_role", create_type=False),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.UniqueConstraint("group_id", "user_sub", name="uq_group_member"),
    )


def downgrade() -> None:
    op.drop_table("group_members")
    op.drop_table("groups")

    group_role_enum = sa.Enum("member", "leader", name="group_role")
    group_role_enum.drop(op.get_bind(), checkfirst=True)
