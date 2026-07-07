"""expand allowed user roles

Revision ID: 0003_expand_user_roles
Revises: 0002_clients
Create Date: 2026-07-07
"""

from alembic import op

revision = "0003_expand_user_roles"
down_revision = "0002_clients"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check")
    op.execute(
        """
        ALTER TABLE users
        ADD CONSTRAINT users_role_check
        CHECK (role IN ('admin', 'manager', 'engineer', 'operator', 'observer', 'student'))
        """
    )


def downgrade() -> None:
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check")
    op.execute(
        """
        ALTER TABLE users
        ADD CONSTRAINT users_role_check
        CHECK (role IN ('admin', 'student'))
        """
    )
