from pydantic import BaseModel, Field


class ImplementationInput(BaseModel):
    site_city: str = "Goma"
    latitude: float = Field(default=-1.68)
    panel_count: int = Field(default=26, ge=1)
    panel_power_watts: float = Field(default=550, gt=0)
    average_sun_hours: float = Field(default=5, gt=0)
    system_efficiency: float = Field(default=0.78, gt=0, le=1)
    measured_daily_energy_kwh: float = Field(default=50, ge=0)
    measured_battery_voltage: float = Field(default=48, gt=0)
    expected_battery_voltage: float = Field(default=48, gt=0)
    critical_load_power_watts: float = Field(default=1250, ge=0)
    smart_sleep_savings_percent: float = Field(default=8, ge=0, le=60)


class ImplementationResult(BaseModel):
    recommended_tilt_degrees: float
    recommended_orientation: str
    theoretical_daily_energy_kwh: float
    performance_ratio: float
    energy_gap_kwh: float
    battery_voltage_status: str
    optimized_load_power_watts: float
    installation_checklist: list[str]
    test_protocol: list[str]
    operational_recommendations: list[str]
    alerts: list[str]
