"""extended available inventory

Revision ID: 0007_extended_available_inventory
Revises: 0006_entered_equipment_quantities
Create Date: 2026-07-05
"""

from alembic import op
import sqlalchemy as sa


revision = "0007_extended_available_inventory"
down_revision = "0006_entered_equipment_quantities"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("simulations", sa.Column("installed_controller_count", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("installed_controller_current_a", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("installed_dc_spd_count", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("installed_ac_spd_count", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("installed_earthing_kit_count", sa.Integer(), nullable=False, server_default="0"))


def downgrade() -> None:
    op.drop_column("simulations", "installed_earthing_kit_count")
    op.drop_column("simulations", "installed_ac_spd_count")
    op.drop_column("simulations", "installed_dc_spd_count")
    op.drop_column("simulations", "installed_controller_current_a")
    op.drop_column("simulations", "installed_controller_count")
