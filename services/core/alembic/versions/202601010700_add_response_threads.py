"""add threaded question responses

Revision ID: 202601010700
Revises: 202601010600
Create Date: 2026-01-01 07:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "202601010700"
down_revision = "202601010600"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "study_question_responses",
        sa.Column("parent_response_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_question_response_parent",
        "study_question_responses",
        "study_question_responses",
        ["parent_response_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.drop_constraint("uq_question_response", "study_question_responses", type_="unique")
    op.create_unique_constraint(
        "uq_question_response",
        "study_question_responses",
        ["question_id", "group_id", "user_sub", "parent_response_id"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_question_response", "study_question_responses", type_="unique")
    op.drop_constraint("fk_question_response_parent", "study_question_responses", type_="foreignkey")
    op.drop_column("study_question_responses", "parent_response_id")
    op.create_unique_constraint(
        "uq_question_response",
        "study_question_responses",
        ["question_id", "group_id", "user_sub"],
    )
