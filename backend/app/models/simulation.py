from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class Simulation(SQLModel, table=True):
    __tablename__ = "simulations"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id", index=True)
    site_id: int = Field(foreign_key="sites.id", index=True)
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
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

