"""dimensioning constraints

Revision ID: 0003_dimensioning_constraints
Revises: 0002_clients
Create Date: 2026-07-05
"""

from alembic import op
import sqlalchemy as sa
import sqlmodel

revision = "0003_dimensioning_constraints"
down_revision = "0002_clients"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("sites", sa.Column("latitude", sa.Float(), nullable=False, server_default="0"))
    op.add_column("sites", sa.Column("longitude", sa.Float(), nullable=False, server_default="0"))
    op.add_column(
        "sites", sa.Column("target_backup_hours", sa.Float(), nullable=False, server_default="24")
    )
    op.add_column(
        "sites", sa.Column("available_area_m2", sa.Float(), nullable=False, server_default="0")
    )
    op.add_column(
        "sites", sa.Column("usable_area_ratio", sa.Float(), nullable=False, server_default="1")
    )
    op.add_column(
        "sites", sa.Column("generator_available", sa.Boolean(), nullable=False, server_default=sa.true())
    )
    op.add_column(
        "sites",
        sa.Column("generator_failure_scenario", sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    op.add_column(
        "equipment", sa.Column("is_critical", sa.Boolean(), nullable=False, server_default=sa.true())
    )
    op.add_column(
        "equipment", sa.Column("notes", sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default="")
    )

    op.add_column(
        "simulations",
        sa.Column("panel_type", sqlmodel.sql.sqltypes.AutoString(length=80), nullable=False, server_default="Monocristallin"),
    )
    op.add_column("simulations", sa.Column("panel_length_m", sa.Float(), nullable=False, server_default="2.28"))
    op.add_column("simulations", sa.Column("panel_width_m", sa.Float(), nullable=False, server_default="1.13"))
    op.add_column("simulations", sa.Column("panel_area_m2", sa.Float(), nullable=False, server_default="2.58"))
    op.add_column(
        "simulations", sa.Column("panel_spacing_factor", sa.Float(), nullable=False, server_default="1.2")
    )
    op.add_column(
        "simulations",
        sa.Column("battery_type", sqlmodel.sql.sqltypes.AutoString(length=80), nullable=False, server_default="LiFePO4"),
    )
    op.add_column(
        "simulations", sa.Column("battery_energy_kwh", sa.Float(), nullable=False, server_default="2.4")
    )
    op.add_column(
        "simulations", sa.Column("controller_efficiency", sa.Float(), nullable=False, server_default="0.96")
    )
    op.add_column(
        "simulations", sa.Column("inverter_efficiency", sa.Float(), nullable=False, server_default="0.93")
    )
    op.add_column(
        "simulations", sa.Column("cable_loss_factor", sa.Float(), nullable=False, server_default="0.03")
    )
    op.add_column(
        "simulations",
        sa.Column("temperature_loss_factor", sa.Float(), nullable=False, server_default="0.05"),
    )
    op.add_column(
        "simulations", sa.Column("dust_loss_factor", sa.Float(), nullable=False, server_default="0.03")
    )
    op.add_column(
        "simulations", sa.Column("safety_factor", sa.Float(), nullable=False, server_default="1.25")
    )

    op.add_column(
        "simulation_results", sa.Column("critical_power_watts", sa.Float(), nullable=False, server_default="0")
    )
    op.add_column(
        "simulation_results",
        sa.Column("non_critical_power_watts", sa.Float(), nullable=False, server_default="0"),
    )
    op.add_column(
        "simulation_results", sa.Column("critical_energy_wh", sa.Float(), nullable=False, server_default="0")
    )
    op.add_column(
        "simulation_results", sa.Column("non_critical_energy_wh", sa.Float(), nullable=False, server_default="0")
    )
    op.add_column(
        "simulation_results",
        sa.Column("panel_surface_required_m2", sa.Float(), nullable=False, server_default="0"),
    )
    op.add_column(
        "simulation_results",
        sa.Column("panel_surface_with_spacing_m2", sa.Float(), nullable=False, server_default="0"),
    )
    op.add_column(
        "simulation_results", sa.Column("available_surface_m2", sa.Float(), nullable=False, server_default="0")
    )
    op.add_column(
        "simulation_results",
        sa.Column("surface_status", sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default=""),
    )
    op.add_column(
        "simulation_results", sa.Column("backup_time_hours", sa.Float(), nullable=False, server_default="0")
    )
    op.add_column(
        "simulation_results",
        sa.Column("feasibility_status", sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default=""),
    )
    op.add_column(
        "simulation_results",
        sa.Column("dimensioning_state", sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default=""),
    )
    op.add_column(
        "simulation_results",
        sa.Column("load_shedding_required", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.add_column(
        "simulation_results",
        sa.Column("load_shedding_message", sqlmodel.sql.sqltypes.AutoString(), nullable=False, server_default=""),
    )
    op.add_column(
        "simulation_results", sa.Column("warnings_json", sa.Text(), nullable=False, server_default="[]")
    )
    op.add_column(
        "simulation_results",
        sa.Column("recommended_configuration_json", sa.Text(), nullable=False, server_default="{}"),
    )


def downgrade() -> None:
    op.drop_column("simulation_results", "recommended_configuration_json")
    op.drop_column("simulation_results", "warnings_json")
    op.drop_column("simulation_results", "load_shedding_message")
    op.drop_column("simulation_results", "load_shedding_required")
    op.drop_column("simulation_results", "dimensioning_state")
    op.drop_column("simulation_results", "feasibility_status")
    op.drop_column("simulation_results", "backup_time_hours")
    op.drop_column("simulation_results", "surface_status")
    op.drop_column("simulation_results", "available_surface_m2")
    op.drop_column("simulation_results", "panel_surface_with_spacing_m2")
    op.drop_column("simulation_results", "panel_surface_required_m2")
    op.drop_column("simulation_results", "non_critical_energy_wh")
    op.drop_column("simulation_results", "critical_energy_wh")
    op.drop_column("simulation_results", "non_critical_power_watts")
    op.drop_column("simulation_results", "critical_power_watts")

    op.drop_column("simulations", "safety_factor")
    op.drop_column("simulations", "dust_loss_factor")
    op.drop_column("simulations", "temperature_loss_factor")
    op.drop_column("simulations", "cable_loss_factor")
    op.drop_column("simulations", "inverter_efficiency")
    op.drop_column("simulations", "controller_efficiency")
    op.drop_column("simulations", "battery_energy_kwh")
    op.drop_column("simulations", "battery_type")
    op.drop_column("simulations", "panel_spacing_factor")
    op.drop_column("simulations", "panel_area_m2")
    op.drop_column("simulations", "panel_width_m")
    op.drop_column("simulations", "panel_length_m")
    op.drop_column("simulations", "panel_type")

    op.drop_column("equipment", "notes")
    op.drop_column("equipment", "is_critical")

    op.drop_column("sites", "generator_failure_scenario")
    op.drop_column("sites", "generator_available")
    op.drop_column("sites", "usable_area_ratio")
    op.drop_column("sites", "available_area_m2")
    op.drop_column("sites", "target_backup_hours")
    op.drop_column("sites", "longitude")
    op.drop_column("sites", "latitude")
