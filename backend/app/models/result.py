from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Column, Text
from sqlmodel import Field, SQLModel


class SimulationResult(SQLModel, table=True):
    __tablename__ = "simulation_results"

    id: Optional[int] = Field(default=None, primary_key=True)
    simulation_id: int = Field(foreign_key="simulations.id", index=True, unique=True)
    total_power_watts: float
    critical_power_watts: float = 0
    non_critical_power_watts: float = 0
    apparent_power_va: float = 0
    daily_energy_wh: float
    critical_energy_wh: float = 0
    non_critical_energy_wh: float = 0
    corrected_energy_wh: float
    required_pv_power_wc: float
    number_of_panels: int
    panel_unit_area_m2: float = 0
    panel_total_area_m2: float = 0
    panel_total_area_with_spacing_m2: float = 0
    panel_surface_required_m2: float = 0
    panel_surface_with_spacing_m2: float = 0
    available_surface_m2: float = 0
    surface_status: str = ""
    required_battery_capacity_wh: float
    required_battery_capacity_ah: float
    number_of_batteries: int
    backup_time_hours: float = 0
    controller_current_a: float
    inverter_power_watts: float
    dc_cable_section_mm2: float = 0
    ac_cable_section_mm2: float = 0
    earth_cable_section_mm2: float = 0
    dc_breaker_rating_a: float = 0
    ac_breaker_rating_a: float = 0
    dc_spd_required: bool = False
    ac_spd_required: bool = False
    lightning_protection_required: bool = False
    earthing_required: bool = False
    recommended_earthing_resistance_ohm: float = 0
    measured_earthing_resistance_ohm: float = 0
    grounding_status: str = ""
    feasibility_status: str = ""
    dimensioning_state: str = ""
    load_shedding_required: bool = False
    load_shedding_message: str = ""
    warnings_json: str = Field(default="[]", sa_column=Column(Text))
    recommended_configuration_json: str = Field(default="{}", sa_column=Column(Text))
    pv_cost: float = 0
    battery_cost: float = 0
    inverter_cost: float = 0
    controller_cost: float = 0
    air_conditioner_cost: float = 0
    protection_cost: float = 0
    installation_cost: float = 0
    accessories_cost: float = 0
    maintenance_cost: float = 0
    total_investment_cost: float = 0
    snel_operating_cost: float = 0
    generator_operating_cost: float = 0
    total_cost: float
    recommendations: str = Field(default="", sa_column=Column(Text))
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
