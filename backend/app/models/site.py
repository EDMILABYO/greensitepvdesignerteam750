from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class Site(SQLModel, table=True):
    __tablename__ = "sites"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id", index=True)
    name: str = Field(max_length=150)
    city: str = Field(max_length=80)
    country: str = Field(max_length=80)
    site_type: str = Field(max_length=100)
    description: str = ""
    latitude: float = Field(default=0)
    longitude: float = Field(default=0)
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
    snel_available: bool = Field(default=True)
    generator_available: bool = Field(default=True)
    generator_failure_scenario: bool = Field(default=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
