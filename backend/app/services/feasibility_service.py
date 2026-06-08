from app.schemas.feasibility_schema import FeasibilityInput, FeasibilityResult


def calculate_feasibility(payload: FeasibilityInput) -> FeasibilityResult:
    annual_energy_kwh = payload.daily_energy_wh * 365 / 1000
    annual_diesel_liters = annual_energy_kwh * payload.diesel_liters_per_kwh
    annual_diesel_opex = (
        annual_diesel_liters * payload.diesel_price_per_liter * payload.logistics_factor
        + payload.generator_maintenance_per_year
    )
    diesel_tco = annual_diesel_opex * payload.study_years
    solar_tco = payload.solar_capex + payload.solar_opex_per_year * payload.study_years
    annual_savings = max(0, annual_diesel_opex - payload.solar_opex_per_year)
    payback_years = (
        round(payload.solar_capex / annual_savings, 2) if annual_savings > 0 else None
    )
    co2_avoided = annual_diesel_liters * payload.co2_kg_per_liter

    score = 40
    if payload.average_ghi_kwh_m2_day >= 4.5:
        score += 20
    if annual_savings > 0:
        score += 20
    if payback_years is not None and payback_years <= 5:
        score += 10
    if solar_tco < diesel_tco:
        score += 10
    score = min(score, 100)

    verdict = "Favorable" if score >= 70 else "A approfondir"
    recommendations = [
        "Valider les charges critiques BTS/IP sur une semaine type.",
        "Confirmer le gisement solaire local avec des donnees GHI mensuelles.",
        "Comparer le scenario solaire au groupe diesel sur le TCO complet.",
    ]
    if payload.average_ghi_kwh_m2_day < 4:
        recommendations.append("GHI faible: augmenter la marge PV ou envisager une hybridation.")
    if payback_years is not None and payback_years > 7:
        recommendations.append("Retour sur investissement long: optimiser CAPEX ou OPEX.")
    if co2_avoided > 10000:
        recommendations.append("Fort potentiel de reduction CO2 a valoriser dans le rapport RSE.")

    return FeasibilityResult(
        annual_energy_kwh=round(annual_energy_kwh, 2),
        annual_diesel_liters=round(annual_diesel_liters, 2),
        annual_diesel_opex=round(annual_diesel_opex, 2),
        diesel_tco=round(diesel_tco, 2),
        solar_tco=round(solar_tco, 2),
        annual_savings=round(annual_savings, 2),
        payback_years=payback_years,
        co2_avoided_kg_per_year=round(co2_avoided, 2),
        feasibility_score=score,
        verdict=verdict,
        recommendations=recommendations,
    )
