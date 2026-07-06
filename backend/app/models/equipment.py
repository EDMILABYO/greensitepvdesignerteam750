from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class Equipment(SQLModel, table=True):
    __tablename__ = "equipment"

    id: Optional[int] = Field(default=None, primary_key=True)
    site_id: int = Field(foreign_key="sites.id", index=True)
    name: str = Field(max_length=120)
    category: str = Field(max_length=80)
    power_watts: float = Field(gt=0)
    quantity: int = Field(default=1, ge=1)
    hours_per_day: float = Field(default=24, ge=0, le=24)
    is_critical: bool = Field(default=True)
    notes: str = ""
    position_x_m: float = Field(default=0, ge=0)
    position_y_m: float = Field(default=0, ge=0)
    footprint_length_m: float = Field(default=0, ge=0)
    footprint_width_m: float = Field(default=0, ge=0)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
