from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class SiteBase(BaseModel):
    name: str
    city: str
    country: str
    site_type: str
    description: str = ""
    latitude: float = 0
    longitude: float = 0
    operating_hours_per_day: float = Field(default=24, ge=0, le=24)
    autonomy_days: float = Field(default=2, gt=0)
    target_backup_hours: float = Field(default=24, gt=0)
    solar_irradiation_hours: float = Field(default=5, gt=0)
    system_efficiency: float = Field(default=0.8, gt=0, le=1)
    system_voltage: int = Field(default=48)
    total_area_m2: float = Field(default=0, ge=0)
    tower_area_m2: float = Field(default=0, ge=0)
    rack_area_m2: float = Field(default=0, ge=0)
    generator_area_m2: float = Field(default=0, ge=0)
    other_blocked_area_m2: float = Field(default=0, ge=0)
    available_area_m2: float = Field(default=0, ge=0)
    usable_area_ratio: float = Field(default=1, gt=0, le=1)
    layout_length_m: float = Field(default=0, ge=0)
    layout_width_m: float = Field(default=0, ge=0)
    snel_available: bool = True
    generator_available: bool = True
    generator_failure_scenario: bool = True


class SiteCreate(SiteBase):
    pass


class SiteUpdate(BaseModel):
    name: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    site_type: Optional[str] = None
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    operating_hours_per_day: Optional[float] = Field(default=None, ge=0, le=24)
    autonomy_days: Optional[float] = Field(default=None, gt=0)
    target_backup_hours: Optional[float] = Field(default=None, gt=0)
    solar_irradiation_hours: Optional[float] = Field(default=None, gt=0)
    system_efficiency: Optional[float] = Field(default=None, gt=0, le=1)
    system_voltage: Optional[int] = None
    total_area_m2: Optional[float] = Field(default=None, ge=0)
    tower_area_m2: Optional[float] = Field(default=None, ge=0)
    rack_area_m2: Optional[float] = Field(default=None, ge=0)
    generator_area_m2: Optional[float] = Field(default=None, ge=0)
    other_blocked_area_m2: Optional[float] = Field(default=None, ge=0)
    available_area_m2: Optional[float] = Field(default=None, ge=0)
    usable_area_ratio: Optional[float] = Field(default=None, gt=0, le=1)
    layout_length_m: Optional[float] = Field(default=None, ge=0)
    layout_width_m: Optional[float] = Field(default=None, ge=0)
    snel_available: Optional[bool] = None
    generator_available: Optional[bool] = None
    generator_failure_scenario: Optional[bool] = None


class SiteRead(SiteBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
