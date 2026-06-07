from math import ceil

from app.models.equipment import Equipment
from app.models.result import SimulationResult
from app.models.simulation import Simulation
from app.models.site import Site


def build_recommendations(
    site: Site,
    total_power_watts: float,
    daily_energy_wh: float,
    required_pv_power_wc: float,
    required_battery_capacity_ah: float,
) -> list[str]:
    recommendations = [
        "Verifier l'orientation des panneaux, la ventilation des batteries et la protection DC/AC.",
    ]
    if daily_energy_wh > 30000:
        recommendations.append("La consommation est elevee: optimiser les equipements telecom.")
    if site.autonomy_days > 3:
        recommendations.append("Une autonomie superieure a 3 jours augmente fortement le cout.")
    if site.system_efficiency < 0.7:
        recommendations.append("Le rendement est faible: choisir des composants de meilleure qualite.")
    if required_pv_power_wc > 10000:
        recommendations.append("La puissance PV depasse 10 kWc: prevoir une etude technique detaillee.")
    if required_battery_capacity_ah > 1200:
        recommendations.append("La capacite batterie est elevee: envisager une solution hybride solaire + groupe.")
    if total_power_watts == 0:
        recommendations.append("Ajouter au moins un equipement pour rendre la simulation representative.")
    return recommendations


def calculate_simulation(
    site: Site,
    equipment: list[Equipment],
    simulation: Simulation,
) -> SimulationResult:
    total_power_watts = sum(item.power_watts * item.quantity for item in equipment)
    daily_energy_wh = sum(
        item.power_watts * item.quantity * item.hours_per_day for item in equipment
    )
    corrected_energy_wh = daily_energy_wh / site.system_efficiency
    required_pv_power_wc = corrected_energy_wh / site.solar_irradiation_hours
    number_of_panels = ceil(required_pv_power_wc / simulation.panel_power_watts)
    required_battery_capacity_wh = daily_energy_wh * site.autonomy_days
    base_battery_capacity_ah = required_battery_capacity_wh / site.system_voltage
    required_battery_capacity_ah = base_battery_capacity_ah / simulation.battery_dod
    number_of_batteries = ceil(
        required_battery_capacity_ah / simulation.battery_capacity_ah
    )
    controller_current_a = (required_pv_power_wc / site.system_voltage) * 1.25
    inverter_power_watts = total_power_watts * 1.25
    total_cost = (
        number_of_panels * simulation.panel_unit_price
        + number_of_batteries * simulation.battery_unit_price
        + simulation.inverter_price
        + simulation.controller_price
        + simulation.accessories_price
        + simulation.labor_price
        + simulation.maintenance_price
    )
    recommendations = build_recommendations(
        site,
        total_power_watts,
        daily_energy_wh,
        required_pv_power_wc,
        required_battery_capacity_ah,
    )

    return SimulationResult(
        simulation_id=simulation.id or 0,
        total_power_watts=round(total_power_watts, 2),
        daily_energy_wh=round(daily_energy_wh, 2),
        corrected_energy_wh=round(corrected_energy_wh, 2),
        required_pv_power_wc=round(required_pv_power_wc, 2),
        number_of_panels=number_of_panels,
        required_battery_capacity_wh=round(required_battery_capacity_wh, 2),
        required_battery_capacity_ah=round(required_battery_capacity_ah, 2),
        number_of_batteries=number_of_batteries,
        controller_current_a=round(controller_current_a, 2),
        inverter_power_watts=round(inverter_power_watts, 2),
        total_cost=round(total_cost, 2),
        recommendations="\n".join(recommendations),
    )
