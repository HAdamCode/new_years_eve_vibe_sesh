"""add group study/session instances

Revision ID: 202601010900
Revises: 202601010800
Create Date: 2026-01-01 09:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "202601010900"
down_revision = "202601010800"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "group_studies",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "group_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("groups.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "study_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("studies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.UniqueConstraint("group_id", "study_id", name="uq_group_study"),
    )

    op.create_table(
        "group_sessions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "group_study_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("group_studies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "study_session_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("study_sessions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.UniqueConstraint("group_study_id", "study_session_id", name="uq_group_session"),
    )

    op.add_column(
        "study_session_notes",
        sa.Column("group_session_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_session_notes_group_session",
        "study_session_notes",
        "group_sessions",
        ["group_session_id"],
        ["id"],
        ondelete="CASCADE",
    )

    op.add_column(
        "study_question_responses",
        sa.Column("group_session_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_question_responses_group_session",
        "study_question_responses",
        "group_sessions",
        ["group_session_id"],
        ["id"],
        ondelete="CASCADE",
    )

    op.add_column(
        "study_passage_likes",
        sa.Column("group_session_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_passage_likes_group_session",
        "study_passage_likes",
        "group_sessions",
        ["group_session_id"],
        ["id"],
        ondelete="CASCADE",
    )

    op.add_column(
        "study_passage_comments",
        sa.Column("group_session_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_passage_comments_group_session",
        "study_passage_comments",
        "group_sessions",
        ["group_session_id"],
        ["id"],
        ondelete="CASCADE",
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_passage_comments_group_session",
        "study_passage_comments",
        type_="foreignkey",
    )
    op.drop_column("study_passage_comments", "group_session_id")

    op.drop_constraint(
        "fk_passage_likes_group_session",
        "study_passage_likes",
        type_="foreignkey",
    )
    op.drop_column("study_passage_likes", "group_session_id")

    op.drop_constraint(
        "fk_question_responses_group_session",
        "study_question_responses",
        type_="foreignkey",
    )
    op.drop_column("study_question_responses", "group_session_id")

    op.drop_constraint(
        "fk_session_notes_group_session",
        "study_session_notes",
        type_="foreignkey",
    )
    op.drop_column("study_session_notes", "group_session_id")

    op.drop_table("group_sessions")
    op.drop_table("group_studies")
