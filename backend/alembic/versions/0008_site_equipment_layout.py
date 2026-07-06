"""site equipment layout

Revision ID: 0008_site_equipment_layout
Revises: 0007_extended_available_inventory
Create Date: 2026-07-06
"""

from alembic import op
import sqlalchemy as sa


revision = "0008_site_equipment_layout"
down_revision = "0007_extended_available_inventory"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("sites", sa.Column("layout_length_m", sa.Float(), nullable=False, server_default="0"))
    op.add_column("sites", sa.Column("layout_width_m", sa.Float(), nullable=False, server_default="0"))
    op.add_column("equipment", sa.Column("position_x_m", sa.Float(), nullable=False, server_default="0"))
    op.add_column("equipment", sa.Column("position_y_m", sa.Float(), nullable=False, server_default="0"))
    op.add_column("equipment", sa.Column("footprint_length_m", sa.Float(), nullable=False, server_default="0"))
    op.add_column("equipment", sa.Column("footprint_width_m", sa.Float(), nullable=False, server_default="0"))


def downgrade() -> None:
    op.drop_column("equipment", "footprint_width_m")
    op.drop_column("equipment", "footprint_length_m")
    op.drop_column("equipment", "position_y_m")
    op.drop_column("equipment", "position_x_m")
    op.drop_column("sites", "layout_width_m")
    op.drop_column("sites", "layout_length_m")
