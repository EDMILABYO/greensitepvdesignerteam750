from app.schemas.implementation_schema import ImplementationInput, ImplementationResult


def calculate_implementation(payload: ImplementationInput) -> ImplementationResult:
    tilt = max(10, min(35, abs(payload.latitude) + 10))
    orientation = "Nord" if payload.latitude < 0 else "Sud"
    theoretical_energy = (
        payload.panel_count
        * payload.panel_power_watts
        * payload.average_sun_hours
        * payload.system_efficiency
        / 1000
    )
    performance_ratio = (
        payload.measured_daily_energy_kwh / theoretical_energy
        if theoretical_energy > 0
        else 0
    )
    energy_gap = payload.measured_daily_energy_kwh - theoretical_energy
    voltage_delta = abs(payload.measured_battery_voltage - payload.expected_battery_voltage)
    battery_status = "Normal" if voltage_delta <= 2 else "A verifier"
    optimized_load = payload.critical_load_power_watts * (
        1 - payload.smart_sleep_savings_percent / 100
    )

    checklist = [
        "Verifier les structures de support et l'ancrage mecanique.",
        "Orienter les panneaux selon l'hemisphere du site.",
        "Regler l'inclinaison recommandee et eviter les zones d'ombrage.",
        "Controler la polarite DC avant raccordement au regulateur.",
        "Installer mise a la terre, parafoudre, disjoncteurs et fusibles.",
        "Etiqueter les circuits PV, batterie, regulateur, onduleur et charges.",
    ]
    protocol = [
        "Mesurer tension et courant du champ PV a vide et en charge.",
        "Comparer la production quotidienne mesuree a la production theorique.",
        "Tester bascule batterie/onduleur en coupant l'alimentation auxiliaire.",
        "Valider que les charges critiques BTS/IP restent prioritaires.",
        "Consigner les valeurs initiales comme reference de maintenance.",
    ]
    recommendations = [
        "Activer une supervision distante pour suivre production, charge et batteries.",
        "Configurer une mise en veille intelligente des charges non critiques.",
        "Analyser les ecarts de production pendant au moins 7 jours.",
    ]
    alerts: list[str] = []
    if performance_ratio < 0.75:
        alerts.append("Performance faible: verifier ombrage, poussiere, cablage ou MPPT.")
    if performance_ratio > 1.15:
        alerts.append("Production mesuree atypique: verifier les donnees saisies.")
    if battery_status != "Normal":
        alerts.append("Tension batterie hors tolerance: inspecter banc batterie et connexions.")
    if not alerts:
        alerts.append("Aucune alerte critique detectee.")

    return ImplementationResult(
        recommended_tilt_degrees=round(tilt, 1),
        recommended_orientation=orientation,
        theoretical_daily_energy_kwh=round(theoretical_energy, 2),
        performance_ratio=round(performance_ratio, 3),
        energy_gap_kwh=round(energy_gap, 2),
        battery_voltage_status=battery_status,
        optimized_load_power_watts=round(optimized_load, 2),
        installation_checklist=checklist,
        test_protocol=protocol,
        operational_recommendations=recommendations,
        alerts=alerts,
    )
