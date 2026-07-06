from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class EquipmentBase(BaseModel):
    name: str
    category: str
    power_watts: float = Field(gt=0)
    quantity: int = Field(default=1, ge=1)
    hours_per_day: float = Field(default=24, ge=0, le=24)
    is_critical: bool = True
    notes: str = ""
    position_x_m: float = Field(default=0, ge=0)
    position_y_m: float = Field(default=0, ge=0)
    footprint_length_m: float = Field(default=0, ge=0)
    footprint_width_m: float = Field(default=0, ge=0)


class EquipmentCreate(EquipmentBase):
    pass


class EquipmentUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    power_watts: Optional[float] = Field(default=None, gt=0)
    quantity: Optional[int] = Field(default=None, ge=1)
    hours_per_day: Optional[float] = Field(default=None, ge=0, le=24)
    is_critical: Optional[bool] = None
    notes: Optional[str] = None
    position_x_m: Optional[float] = Field(default=None, ge=0)
    position_y_m: Optional[float] = Field(default=None, ge=0)
    footprint_length_m: Optional[float] = Field(default=None, ge=0)
    footprint_width_m: Optional[float] = Field(default=None, ge=0)


class EquipmentRead(EquipmentBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    site_id: int
    created_at: datetime
    updated_at: datetime
