from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.equipment_schema import EquipmentRead
from app.schemas.site_schema import SiteRead


class SimulationCreate(BaseModel):
    site_id: int
    panel_power_watts: float = Field(default=550, gt=0)
    battery_capacity_ah: float = Field(default=200, gt=0)
    battery_voltage: float = Field(default=12, gt=0)
    battery_dod: float = Field(default=0.8, gt=0, le=1)
    panel_unit_price: float = Field(default=150, ge=0)
    battery_unit_price: float = Field(default=250, ge=0)
    inverter_price: float = Field(default=500, ge=0)
    controller_price: float = Field(default=300, ge=0)
    accessories_price: float = Field(default=400, ge=0)
    labor_price: float = Field(default=500, ge=0)
    maintenance_price: float = Field(default=0, ge=0)


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
    daily_energy_wh: float
    corrected_energy_wh: float
    required_pv_power_wc: float
    number_of_panels: int
    required_battery_capacity_wh: float
    required_battery_capacity_ah: float
    number_of_batteries: int
    controller_current_a: float
    inverter_power_watts: float
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
