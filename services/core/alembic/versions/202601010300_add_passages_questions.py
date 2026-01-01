"""add study passages and questions

Revision ID: 202601010300
Revises: 202601010200
Create Date: 2026-01-01 03:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "202601010300"
down_revision = "202601010200"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "study_passages",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "session_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("study_sessions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("book", sa.String(length=120), nullable=False),
        sa.Column("chapter", sa.Integer(), nullable=False),
        sa.Column("start_verse", sa.Integer(), nullable=True),
        sa.Column("end_verse", sa.Integer(), nullable=True),
        sa.Column("version", sa.String(length=20), nullable=True),
        sa.Column("text", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )

    op.create_table(
        "study_questions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "session_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("study_sessions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("question", sa.Text(), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_table("study_questions")
    op.drop_table("study_passages")
