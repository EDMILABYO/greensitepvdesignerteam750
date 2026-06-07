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
    operating_hours_per_day: float = Field(default=24, ge=0, le=24)
    autonomy_days: float = Field(default=2, gt=0)
    solar_irradiation_hours: float = Field(default=5, gt=0)
    system_efficiency: float = Field(default=0.8, gt=0, le=1)
    system_voltage: int = Field(default=48)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

