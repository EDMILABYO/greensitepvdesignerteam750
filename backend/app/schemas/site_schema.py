from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class SiteBase(BaseModel):
    name: str
    city: str
    country: str
    site_type: str
    description: str = ""
    operating_hours_per_day: float = Field(default=24, ge=0, le=24)
    autonomy_days: float = Field(default=2, gt=0)
    solar_irradiation_hours: float = Field(default=5, gt=0)
    system_efficiency: float = Field(default=0.8, gt=0, le=1)
    system_voltage: int = Field(default=48)


class SiteCreate(SiteBase):
    pass


class SiteUpdate(BaseModel):
    name: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None
    site_type: Optional[str] = None
    description: Optional[str] = None
    operating_hours_per_day: Optional[float] = Field(default=None, ge=0, le=24)
    autonomy_days: Optional[float] = Field(default=None, gt=0)
    solar_irradiation_hours: Optional[float] = Field(default=None, gt=0)
    system_efficiency: Optional[float] = Field(default=None, gt=0, le=1)
    system_voltage: Optional[int] = None


class SiteRead(SiteBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
