from pydantic import BaseModel, Field


class MaintenanceInput(BaseModel):
    availability_percent: float = Field(default=99.0, ge=0, le=100)
    performance_ratio: float = Field(default=0.85, ge=0)
    battery_soc_percent: float = Field(default=80, ge=0, le=100)
    battery_soh_percent: float = Field(default=92, ge=0, le=100)
    battery_cycles: int = Field(default=450, ge=0)
    days_since_panel_cleaning: int = Field(default=20, ge=0)
    days_since_electrical_inspection: int = Field(default=45, ge=0)
    annual_diesel_liters_avoided: float = Field(default=4500, ge=0)
    co2_kg_per_liter: float = Field(default=2.68, gt=0)
    sites_replicable_count: int = Field(default=1, ge=1)


class MaintenanceResult(BaseModel):
    health_score: int
    availability_status: str
    energy_status: str
    battery_status: str
    co2_avoided_kg_per_year: float
    network_co2_potential_kg_per_year: float
    next_panel_cleaning_days: int
    next_electrical_inspection_days: int
    maintenance_tasks: list[str]
    alerts: list[str]
    kpis: list[str]
    valorization_points: list[str]
