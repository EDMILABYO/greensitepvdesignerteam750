"""initial schema

Revision ID: 0001_initial
Revises:
Create Date: 2026-06-07
"""
from alembic import op
import sqlalchemy as sa
import sqlmodel

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("full_name", sqlmodel.sql.sqltypes.AutoString(length=120), nullable=False),
        sa.Column("email", sqlmodel.sql.sqltypes.AutoString(length=255), nullable=False),
        sa.Column("hashed_password", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column("role", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
    )
    op.create_index(op.f("ix_users_email"), "users", ["email"], unique=False)
    op.create_table(
        "sites",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("name", sqlmodel.sql.sqltypes.AutoString(length=150), nullable=False),
        sa.Column("city", sqlmodel.sql.sqltypes.AutoString(length=80), nullable=False),
        sa.Column("country", sqlmodel.sql.sqltypes.AutoString(length=80), nullable=False),
        sa.Column("site_type", sqlmodel.sql.sqltypes.AutoString(length=100), nullable=False),
        sa.Column("description", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column("operating_hours_per_day", sa.Float(), nullable=False),
        sa.Column("autonomy_days", sa.Float(), nullable=False),
        sa.Column("solar_irradiation_hours", sa.Float(), nullable=False),
        sa.Column("system_efficiency", sa.Float(), nullable=False),
        sa.Column("system_voltage", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_sites_user_id"), "sites", ["user_id"], unique=False)
    op.create_table(
        "equipment",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("site_id", sa.Integer(), nullable=False),
        sa.Column("name", sqlmodel.sql.sqltypes.AutoString(length=120), nullable=False),
        sa.Column("category", sqlmodel.sql.sqltypes.AutoString(length=80), nullable=False),
        sa.Column("power_watts", sa.Float(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("hours_per_day", sa.Float(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["site_id"], ["sites.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_equipment_site_id"), "equipment", ["site_id"], unique=False)
    op.create_table(
        "simulations",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("site_id", sa.Integer(), nullable=False),
        sa.Column("panel_power_watts", sa.Float(), nullable=False),
        sa.Column("battery_capacity_ah", sa.Float(), nullable=False),
        sa.Column("battery_voltage", sa.Float(), nullable=False),
        sa.Column("battery_dod", sa.Float(), nullable=False),
        sa.Column("panel_unit_price", sa.Float(), nullable=False),
        sa.Column("battery_unit_price", sa.Float(), nullable=False),
        sa.Column("inverter_price", sa.Float(), nullable=False),
        sa.Column("controller_price", sa.Float(), nullable=False),
        sa.Column("accessories_price", sa.Float(), nullable=False),
        sa.Column("labor_price", sa.Float(), nullable=False),
        sa.Column("maintenance_price", sa.Float(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["site_id"], ["sites.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_simulations_site_id"), "simulations", ["site_id"], unique=False)
    op.create_index(op.f("ix_simulations_user_id"), "simulations", ["user_id"], unique=False)
    op.create_table(
        "simulation_results",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("simulation_id", sa.Integer(), nullable=False),
        sa.Column("total_power_watts", sa.Float(), nullable=False),
        sa.Column("daily_energy_wh", sa.Float(), nullable=False),
        sa.Column("corrected_energy_wh", sa.Float(), nullable=False),
        sa.Column("required_pv_power_wc", sa.Float(), nullable=False),
        sa.Column("number_of_panels", sa.Integer(), nullable=False),
        sa.Column("required_battery_capacity_wh", sa.Float(), nullable=False),
        sa.Column("required_battery_capacity_ah", sa.Float(), nullable=False),
        sa.Column("number_of_batteries", sa.Integer(), nullable=False),
        sa.Column("controller_current_a", sa.Float(), nullable=False),
        sa.Column("inverter_power_watts", sa.Float(), nullable=False),
        sa.Column("total_cost", sa.Float(), nullable=False),
        sa.Column("recommendations", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["simulation_id"], ["simulations.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("simulation_id"),
    )
    op.create_index(
        op.f("ix_simulation_results_simulation_id"),
        "simulation_results",
        ["simulation_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_table("simulation_results")
    op.drop_table("simulations")
    op.drop_table("equipment")
    op.drop_table("sites")
    op.drop_index(op.f("ix_users_email"), table_name="users")
    op.drop_table("users")
