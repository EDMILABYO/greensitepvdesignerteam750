"""clients table

Revision ID: 0002_clients
Revises: 0001_initial
Create Date: 2026-06-07
"""
from alembic import op
import sqlalchemy as sa
import sqlmodel

revision = "0002_clients"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "clients",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("name", sqlmodel.sql.sqltypes.AutoString(length=150), nullable=False),
        sa.Column("organization", sqlmodel.sql.sqltypes.AutoString(length=150), nullable=False),
        sa.Column("phone", sqlmodel.sql.sqltypes.AutoString(length=40), nullable=False),
        sa.Column("email", sqlmodel.sql.sqltypes.AutoString(length=255), nullable=False),
        sa.Column("address", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column("notes", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_clients_user_id"), "clients", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_clients_user_id"), table_name="clients")
    op.drop_table("clients")
