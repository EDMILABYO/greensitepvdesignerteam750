"""simple backup mode

Revision ID: 0004_simple_backup_mode
Revises: 0003_dimensioning_constraints
Create Date: 2026-07-05
"""

from alembic import op
import sqlalchemy as sa

revision = "0004_simple_backup_mode"
down_revision = "0003_dimensioning_constraints"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("sites", sa.Column("total_area_m2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("sites", sa.Column("tower_area_m2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("sites", sa.Column("rack_area_m2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("sites", sa.Column("generator_area_m2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("sites", sa.Column("other_blocked_area_m2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("sites", sa.Column("snel_available", sa.Boolean(), nullable=False, server_default=sa.true()))

    op.add_column("simulations", sa.Column("critical_active_power_w", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("backup_time_hours", sa.Float(), nullable=False, server_default="1.5"))
    op.add_column("simulations", sa.Column("power_factor", sa.Float(), nullable=False, server_default="0.8"))
    op.add_column("simulations", sa.Column("air_conditioner_power_w", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("air_conditioner_is_critical", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("simulations", sa.Column("other_critical_power_w", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("other_non_critical_power_w", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("battery_efficiency", sa.Float(), nullable=False, server_default="0.95"))
    op.add_column("simulations", sa.Column("air_conditioner_price", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("installation_price", sa.Float(), nullable=False, server_default="500"))
    op.add_column("simulations", sa.Column("snel_operating_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulations", sa.Column("generator_operating_cost", sa.Float(), nullable=False, server_default="0"))

    op.add_column("simulation_results", sa.Column("apparent_power_va", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("panel_unit_area_m2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("panel_total_area_m2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("panel_total_area_with_spacing_m2", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("pv_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("battery_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("inverter_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("controller_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("air_conditioner_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("installation_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("accessories_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("maintenance_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("total_investment_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("snel_operating_cost", sa.Float(), nullable=False, server_default="0"))
    op.add_column("simulation_results", sa.Column("generator_operating_cost", sa.Float(), nullable=False, server_default="0"))


def downgrade() -> None:
    op.drop_column("simulation_results", "generator_operating_cost")
    op.drop_column("simulation_results", "snel_operating_cost")
    op.drop_column("simulation_results", "total_investment_cost")
    op.drop_column("simulation_results", "maintenance_cost")
    op.drop_column("simulation_results", "accessories_cost")
    op.drop_column("simulation_results", "installation_cost")
    op.drop_column("simulation_results", "air_conditioner_cost")
    op.drop_column("simulation_results", "controller_cost")
    op.drop_column("simulation_results", "inverter_cost")
    op.drop_column("simulation_results", "battery_cost")
    op.drop_column("simulation_results", "pv_cost")
    op.drop_column("simulation_results", "panel_total_area_with_spacing_m2")
    op.drop_column("simulation_results", "panel_total_area_m2")
    op.drop_column("simulation_results", "panel_unit_area_m2")
    op.drop_column("simulation_results", "apparent_power_va")

    op.drop_column("simulations", "generator_operating_cost")
    op.drop_column("simulations", "snel_operating_cost")
    op.drop_column("simulations", "installation_price")
    op.drop_column("simulations", "air_conditioner_price")
    op.drop_column("simulations", "battery_efficiency")
    op.drop_column("simulations", "other_non_critical_power_w")
    op.drop_column("simulations", "other_critical_power_w")
    op.drop_column("simulations", "air_conditioner_is_critical")
    op.drop_column("simulations", "air_conditioner_power_w")
    op.drop_column("simulations", "power_factor")
    op.drop_column("simulations", "backup_time_hours")
    op.drop_column("simulations", "critical_active_power_w")

    op.drop_column("sites", "snel_available")
    op.drop_column("sites", "other_blocked_area_m2")
    op.drop_column("sites", "generator_area_m2")
    op.drop_column("sites", "rack_area_m2")
    op.drop_column("sites", "tower_area_m2")
    op.drop_column("sites", "total_area_m2")
