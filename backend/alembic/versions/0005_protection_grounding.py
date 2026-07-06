"""protection and grounding

Revision ID: 0005_protection_grounding
Revises: 0004_simple_backup_mode
Create Date: 2026-07-05
"""

from alembic import op
import sqlalchemy as sa


revision = "0005_protection_grounding"
down_revision = "0004_simple_backup_mode"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("simulations", sa.Column("dc_cable_length_m", sa.Float(), nullable=False, server_default="20"))
    op.add_column("simulations", sa.Column("ac_cable_length_m", sa.Float(), nullable=False, server_default="30"))
    op.add_column("simulations", sa.Column("dc_voltage_drop_limit_percent", sa.Float(), nullable=False, server_default="3"))
    op.add_column("simulations", sa.Column("ac_voltage_drop_limit_percent", sa.Float(), nullable=False, server_default="5"))
    op.add_column("simulations", sa.Column("lightning_protection_required", sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column("simulations", sa.Column("dc_spd_required", sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column("simulations", sa.Column("ac_spd_required", sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column("simulations", sa.Column("earthing_required", sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column("simulations", sa.Column("earthing_resistance_target_ohm", sa.Float(), nullable=False, server_default="5"))
    op.add_column("simulations", sa.Column("earthing_resistance_measured_ohm", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("protection_price", sa.Float(), nullable=False, server_default="250"))

    op.add_column("simulation_results", sa.Column("dc_cable_section_mm2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("ac_cable_section_mm2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("earth_cable_section_mm2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("dc_breaker_rating_a", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("ac_breaker_rating_a", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("dc_spd_required", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("simulation_results", sa.Column("ac_spd_required", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("simulation_results", sa.Column("lightning_protection_required", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("simulation_results", sa.Column("earthing_required", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("simulation_results", sa.Column("recommended_earthing_resistance_ohm", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("measured_earthing_resistance_ohm", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("grounding_status", sa.String(length=120), nullable=False, server_default=""))
    op.add_column("simulation_results", sa.Column("protection_cost", sa.Float(), nullable=False, server_default="0"))


def downgrade() -> None:
    op.drop_column("simulation_results", "protection_cost")
    op.drop_column("simulation_results", "grounding_status")
    op.drop_column("simulation_results", "measured_earthing_resistance_ohm")
    op.drop_column("simulation_results", "recommended_earthing_resistance_ohm")
    op.drop_column("simulation_results", "earthing_required")
    op.drop_column("simulation_results", "lightning_protection_required")
    op.drop_column("simulation_results", "ac_spd_required")
    op.drop_column("simulation_results", "dc_spd_required")
    op.drop_column("simulation_results", "ac_breaker_rating_a")
    op.drop_column("simulation_results", "dc_breaker_rating_a")
    op.drop_column("simulation_results", "earth_cable_section_mm2")
    op.drop_column("simulation_results", "ac_cable_section_mm2")
    op.drop_column("simulation_results", "dc_cable_section_mm2")

    op.drop_column("simulations", "protection_price")
    op.drop_column("simulations", "earthing_resistance_measured_ohm")
    op.drop_column("simulations", "earthing_resistance_target_ohm")
    op.drop_column("simulations", "earthing_required")
    op.drop_column("simulations", "ac_spd_required")
    op.drop_column("simulations", "dc_spd_required")
    op.drop_column("simulations", "lightning_protection_required")
    op.drop_column("simulations", "ac_voltage_drop_limit_percent")
    op.drop_column("simulations", "dc_voltage_drop_limit_percent")
    op.drop_column("simulations", "ac_cable_length_m")
    op.drop_column("simulations", "dc_cable_length_m")
