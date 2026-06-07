from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Column, Text
from sqlmodel import Field, SQLModel


class SimulationResult(SQLModel, table=True):
    __tablename__ = "simulation_results"

    id: Optional[int] = Field(default=None, primary_key=True)
    simulation_id: int = Field(foreign_key="simulations.id", index=True, unique=True)
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
    recommendations: str = Field(default="", sa_column=Column(Text))
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
