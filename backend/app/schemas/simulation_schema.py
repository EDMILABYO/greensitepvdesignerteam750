from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.equipment_schema import EquipmentRead
from app.schemas.site_schema import SiteRead


class SimulationCreate(BaseModel):
    site_id: int
    critical_active_power_w: float = Field(default=0, ge=0)
    backup_time_hours: float = Field(default=1.5, gt=0)
    power_factor: float = Field(default=0.8, gt=0, le=1)
    air_conditioner_power_w: float = Field(default=0, ge=0)
    air_conditioner_is_critical: bool = False
    other_critical_power_w: float = Field(default=0, ge=0)
    other_non_critical_power_w: float = Field(default=0, ge=0)
    panel_power_watts: float = Field(default=550, gt=0)
    panel_type: str = "Monocristallin"
    panel_length_m: float = Field(default=2.28, gt=0)
    panel_width_m: float = Field(default=1.13, gt=0)
    panel_area_m2: float = Field(default=2.58, gt=0)
    panel_spacing_factor: float = Field(default=1.2, ge=1)
    installed_panel_count: int = Field(default=0, ge=0)
    battery_capacity_ah: float = Field(default=200, gt=0)
    battery_voltage: float = Field(default=12, gt=0)
    battery_type: str = "LiFePO4"
    battery_energy_kwh: float = Field(default=2.4, gt=0)
    installed_battery_count: int = Field(default=0, ge=0)
    installed_inverter_power_watts: float = Field(default=0, ge=0)
    installed_controller_count: int = Field(default=0, ge=0)
    installed_controller_current_a: float = Field(default=0, ge=0)
    installed_dc_spd_count: int = Field(default=0, ge=0)
    installed_ac_spd_count: int = Field(default=0, ge=0)
    installed_earthing_kit_count: int = Field(default=0, ge=0)
    battery_dod: float = Field(default=0.8, gt=0, le=1)
    battery_efficiency: float = Field(default=0.95, gt=0, le=1)
    controller_efficiency: float = Field(default=0.96, gt=0, le=1)
    inverter_efficiency: float = Field(default=0.93, gt=0, le=1)
    cable_loss_factor: float = Field(default=0.03, ge=0, le=1)
    dc_cable_length_m: float = Field(default=20, ge=0)
    ac_cable_length_m: float = Field(default=30, ge=0)
    dc_voltage_drop_limit_percent: float = Field(default=3, gt=0, le=10)
    ac_voltage_drop_limit_percent: float = Field(default=5, gt=0, le=10)
    temperature_loss_factor: float = Field(default=0.05, ge=0, le=1)
    dust_loss_factor: float = Field(default=0.03, ge=0, le=1)
    safety_factor: float = Field(default=1.25, ge=1)
    lightning_protection_required: bool = True
    dc_spd_required: bool = True
    ac_spd_required: bool = True
    earthing_required: bool = True
    earthing_resistance_target_ohm: float = Field(default=5, gt=0)
    earthing_resistance_measured_ohm: float = Field(default=0, ge=0)
    panel_unit_price: float = Field(default=150, ge=0)
    battery_unit_price: float = Field(default=250, ge=0)
    inverter_price: float = Field(default=500, ge=0)
    controller_price: float = Field(default=300, ge=0)
    air_conditioner_price: float = Field(default=0, ge=0)
    accessories_price: float = Field(default=400, ge=0)
    protection_price: float = Field(default=250, ge=0)
    installation_price: float = Field(default=500, ge=0)
    labor_price: float = Field(default=500, ge=0)
    maintenance_price: float = Field(default=0, ge=0)
    snel_operating_cost: float = Field(default=0, ge=0)
    generator_operating_cost: float = Field(default=0, ge=0)


class SimulationUpdate(SimulationCreate):
    pass


class SimulationRead(SimulationCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    created_at: datetime


class SimulationResultRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    simulation_id: int
    total_power_watts: float
    critical_power_watts: float
    non_critical_power_watts: float
    apparent_power_va: float
    daily_energy_wh: float
    critical_energy_wh: float
    non_critical_energy_wh: float
    corrected_energy_wh: float
    required_pv_power_wc: float
    number_of_panels: int
    panel_unit_area_m2: float
    panel_total_area_m2: float
    panel_total_area_with_spacing_m2: float
    panel_surface_required_m2: float
    panel_surface_with_spacing_m2: float
    available_surface_m2: float
    surface_status: str
    required_battery_capacity_wh: float
    required_battery_capacity_ah: float
    number_of_batteries: int
    backup_time_hours: float
    controller_current_a: float
    inverter_power_watts: float
    dc_cable_section_mm2: float
    ac_cable_section_mm2: float
    earth_cable_section_mm2: float
    dc_breaker_rating_a: float
    ac_breaker_rating_a: float
    dc_spd_required: bool
    ac_spd_required: bool
    lightning_protection_required: bool
    earthing_required: bool
    recommended_earthing_resistance_ohm: float
    measured_earthing_resistance_ohm: float
    grounding_status: str
    feasibility_status: str
    dimensioning_state: str
    load_shedding_required: bool
    load_shedding_message: str
    warnings_json: str
    recommended_configuration_json: str
    pv_cost: float
    battery_cost: float
    inverter_cost: float
    controller_cost: float
    air_conditioner_cost: float
    protection_cost: float
    installation_cost: float
    accessories_cost: float
    maintenance_cost: float
    total_investment_cost: float
    snel_operating_cost: float
    generator_operating_cost: float
    total_cost: float
    recommendations: str
    created_at: datetime


class SimulationDetail(SimulationRead):
    result: Optional[SimulationResultRead] = None


class ReportRead(BaseModel):
    academic_notice: str
    site: SiteRead
    equipment: list[EquipmentRead]
    simulation: SimulationRead
    result: Optional[SimulationResultRead]
    assumptions: list[str]
