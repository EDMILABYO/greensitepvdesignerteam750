"""entered equipment quantities

Revision ID: 0006_entered_equipment_quantities
Revises: 0005_protection_grounding
Create Date: 2026-07-05
"""

from alembic import op
import sqlalchemy as sa


revision = "0006_entered_equipment_quantities"
down_revision = "0005_protection_grounding"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("simulations", sa.Column("installed_panel_count", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("installed_battery_count", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("installed_inverter_power_watts", sa.Float(), nullable=False, server_default="0"))


def downgrade() -> None:
    op.drop_column("simulations", "installed_inverter_power_watts")
    op.drop_column("simulations", "installed_battery_count")
    op.drop_column("simulations", "installed_panel_count")
