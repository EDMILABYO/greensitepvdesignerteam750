from pydantic import BaseModel, Field


class FeasibilityInput(BaseModel):
    daily_energy_wh: float = Field(gt=0)
    average_ghi_kwh_m2_day: float = Field(default=5, gt=0)
    diesel_liters_per_kwh: float = Field(default=0.35, gt=0)
    diesel_price_per_liter: float = Field(default=1.5, ge=0)
    generator_maintenance_per_year: float = Field(default=1200, ge=0)
    solar_capex: float = Field(default=6500, ge=0)
    solar_opex_per_year: float = Field(default=350, ge=0)
    study_years: int = Field(default=20, gt=0)
    co2_kg_per_liter: float = Field(default=2.68, gt=0)
    logistics_factor: float = Field(default=1.15, gt=0)


class FeasibilityResult(BaseModel):
    annual_energy_kwh: float
    annual_diesel_liters: float
    annual_diesel_opex: float
    diesel_tco: float
    solar_tco: float
    annual_savings: float
    payback_years: float | None
    co2_avoided_kg_per_year: float
    feasibility_score: int
    verdict: str
    recommendations: list[str]
