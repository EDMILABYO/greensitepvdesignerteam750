from app.schemas.maintenance_schema import MaintenanceInput, MaintenanceResult


def evaluate_maintenance(payload: MaintenanceInput) -> MaintenanceResult:
    score = 100
    alerts: list[str] = []

    if payload.availability_percent < 99:
        score -= 15
        alerts.append("Disponibilite inferieure a 99%: analyser les coupures.")
    if payload.performance_ratio < 0.8:
        score -= 20
        alerts.append("Performance ratio faible: nettoyer panneaux et verifier MPPT.")
    if payload.battery_soc_percent < 30:
        score -= 15
        alerts.append("SOC batterie faible: risque de coupure en autonomie.")
    if payload.battery_soh_percent < 80:
        score -= 20
        alerts.append("SOH batterie faible: planifier remplacement ou extension.")
    if payload.days_since_panel_cleaning > 30:
        score -= 10
        alerts.append("Nettoyage panneaux en retard.")
    if payload.days_since_electrical_inspection > 90:
        score -= 10
        alerts.append("Inspection electrique en retard.")

    score = max(0, score)
    co2 = payload.annual_diesel_liters_avoided * payload.co2_kg_per_liter
    next_cleaning = max(0, 30 - payload.days_since_panel_cleaning)
    next_inspection = max(0, 90 - payload.days_since_electrical_inspection)

    maintenance_tasks = [
        f"Nettoyage panneaux dans {next_cleaning} jours.",
        f"Inspection connexions/protections dans {next_inspection} jours.",
        "Verifier serrage DC/AC, corrosion, parafoudre et mise a la terre.",
        "Exporter les KPI mensuels pour le rapport de suivi.",
    ]
    kpis = [
        f"Disponibilite: {payload.availability_percent:.1f}%",
        f"Performance ratio: {payload.performance_ratio * 100:.1f}%",
        f"SOC batterie: {payload.battery_soc_percent:.1f}%",
        f"SOH batterie: {payload.battery_soh_percent:.1f}%",
        f"Cycles batterie: {payload.battery_cycles}",
    ]
    valorization = [
        f"CO2 evite estime: {co2 / 1000:.2f} tonnes/an.",
        f"Potentiel reseau pour {payload.sites_replicable_count} sites: {co2 * payload.sites_replicable_count / 1000:.2f} tonnes/an.",
        "Les KPI peuvent justifier une strategie RSE et une extension multi-sites.",
    ]

    return MaintenanceResult(
        health_score=score,
        availability_status="Excellent" if payload.availability_percent >= 99 else "A surveiller",
        energy_status="Normal" if payload.performance_ratio >= 0.8 else "Degrade",
        battery_status="Normal" if payload.battery_soh_percent >= 80 else "Critique",
        co2_avoided_kg_per_year=round(co2, 2),
        network_co2_potential_kg_per_year=round(co2 * payload.sites_replicable_count, 2),
        next_panel_cleaning_days=next_cleaning,
        next_electrical_inspection_days=next_inspection,
        maintenance_tasks=maintenance_tasks,
        alerts=alerts or ["Aucune alerte critique detectee."],
        kpis=kpis,
        valorization_points=valorization,
    )
