"""add study question responses

Revision ID: 202601010400
Revises: 202601010300
Create Date: 2026-01-01 04:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "202601010400"
down_revision = "202601010300"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "study_question_responses",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "question_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("study_questions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "group_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("user_sub", sa.Text(), nullable=False),
        sa.Column("response", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.UniqueConstraint(
            "question_id",
            "group_id",
            "user_sub",
            name="uq_question_response",
        ),
    )


def downgrade() -> None:
    op.drop_table("study_question_responses")
