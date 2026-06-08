from math import ceil

from app.schemas.design_schema import DesignInput, DesignResult


def calculate_design(payload: DesignInput) -> DesignResult:
    total_power = sum(item.power_watts * item.quantity for item in payload.equipment)
    daily_energy = sum(
        item.power_watts * item.quantity * item.hours_per_day
        for item in payload.equipment
    )
    loss_factor = 1 - (
        payload.wiring_loss_percent
        + payload.temperature_loss_percent
        + payload.dust_loss_percent
    ) / 100
    global_efficiency = max(
        0.1,
        loss_factor * payload.mppt_efficiency * payload.inverter_efficiency,
    )
    corrected_energy = daily_energy / global_efficiency
    pv_power = corrected_energy / payload.solar_irradiation_hours * payload.safety_factor
    panels = ceil(pv_power / payload.panel_power_watts)
    battery_wh = daily_energy * payload.autonomy_days
    battery_ah = battery_wh / payload.system_voltage / payload.battery_dod
    batteries = ceil(battery_ah / payload.battery_capacity_ah)
    controller_current = pv_power / payload.system_voltage * payload.safety_factor
    inverter_power = total_power * payload.safety_factor

    architecture = (
        "PV + batteries + regulateur MPPT + bus DC 48V + onduleur secouru"
        if payload.system_voltage >= 48
        else "PV + batteries + regulateur + onduleur AC"
    )
    protections = [
        "Disjoncteur DC entre champ PV et regulateur",
        "Fusibles batterie adaptes au courant maximal",
        "Parafoudre DC/AC et mise a la terre",
        "Section de cable dimensionnee pour limiter les pertes",
    ]
    recommendations = [
        f"Technologie panneau recommandee: {payload.panel_technology}.",
        f"Technologie batterie choisie: {payload.battery_technology}.",
        f"Regulateur recommande: {payload.controller_type}.",
        "Prevoir un EMS pour prioriser BTS, routeur et transmission.",
    ]
    if payload.controller_type.upper() != "MPPT":
        recommendations.append("Passer en MPPT pour ameliorer l'extraction d'energie.")
    if payload.battery_technology.lower() == "plomb-acide" and payload.battery_dod > 0.5:
        recommendations.append("Reduire le DOD a 50% pour les batteries plomb-acide.")
    if pv_power > 10000:
        recommendations.append("Puissance PV elevee: etude de structure et protections detaillee.")

    return DesignResult(
        daily_energy_wh=round(daily_energy, 2),
        total_power_watts=round(total_power, 2),
        global_efficiency=round(global_efficiency, 3),
        corrected_energy_wh=round(corrected_energy, 2),
        required_pv_power_wc=round(pv_power, 2),
        number_of_panels=panels,
        battery_capacity_wh=round(battery_wh, 2),
        battery_capacity_ah=round(battery_ah, 2),
        number_of_batteries=batteries,
        controller_current_a=round(controller_current, 2),
        inverter_power_watts=round(inverter_power, 2),
        selected_architecture=architecture,
        protections=protections,
        recommendations=recommendations,
    )
