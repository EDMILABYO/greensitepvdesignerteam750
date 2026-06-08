from pydantic import BaseModel, Field


class DesignEquipmentInput(BaseModel):
    name: str
    category: str = "Autre"
    power_watts: float = Field(gt=0)
    quantity: int = Field(default=1, ge=1)
    hours_per_day: float = Field(default=24, ge=0, le=24)


class DesignInput(BaseModel):
    equipment: list[DesignEquipmentInput]
    autonomy_days: float = Field(default=2, gt=0)
    solar_irradiation_hours: float = Field(default=5, gt=0)
    system_voltage: int = Field(default=48)
    panel_power_watts: float = Field(default=550, gt=0)
    panel_technology: str = "Monocristallin"
    battery_capacity_ah: float = Field(default=200, gt=0)
    battery_voltage: float = Field(default=12, gt=0)
    battery_technology: str = "LiFePO4"
    battery_dod: float = Field(default=0.8, gt=0, le=1)
    controller_type: str = "MPPT"
    mppt_efficiency: float = Field(default=0.96, gt=0, le=1)
    wiring_loss_percent: float = Field(default=3, ge=0, le=30)
    temperature_loss_percent: float = Field(default=5, ge=0, le=40)
    dust_loss_percent: float = Field(default=3, ge=0, le=30)
    inverter_efficiency: float = Field(default=0.93, gt=0, le=1)
    safety_factor: float = Field(default=1.25, ge=1)


class DesignResult(BaseModel):
    daily_energy_wh: float
    total_power_watts: float
    global_efficiency: float
    corrected_energy_wh: float
    required_pv_power_wc: float
    number_of_panels: int
    battery_capacity_wh: float
    battery_capacity_ah: float
    number_of_batteries: int
    controller_current_a: float
    inverter_power_watts: float
    selected_architecture: str
    protections: list[str]
    recommendations: list[str]
