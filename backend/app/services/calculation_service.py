import json
from math import ceil

from app.models.equipment import Equipment
from app.models.result import SimulationResult
from app.models.simulation import Simulation
from app.models.site import Site


def compute_usable_area(site: Site) -> float:
    explicit_available = site.available_area_m2 or 0
    constrained_area = (
        (site.total_area_m2 or 0)
        - (site.tower_area_m2 or 0)
        - (site.rack_area_m2 or 0)
        - (site.generator_area_m2 or 0)
        - (site.other_blocked_area_m2 or 0)
    )
    base_area = explicit_available if explicit_available > 0 else max(constrained_area, 0)
    return max(base_area * (site.usable_area_ratio or 1), 0)


def build_recommendations(
    site: Site,
    critical_power_watts: float,
    backup_time_hours: float,
    required_pv_power_wc: float,
    required_battery_capacity_ah: float,
    panel_surface_with_spacing_m2: float,
    available_surface_m2: float,
    feasibility_status: str,
    load_shedding_required: bool,
    grounding_status: str,
) -> list[str]:
    recommendations = [
        "Verifier l'orientation des panneaux, la ventilation des batteries et la protection DC/AC.",
        "Valider les emprises du pylone, du rack et du groupe avant implantation finale.",
        "Installer une mise a la terre commune pour la structure PV, les coffrets, l'onduleur et les equipements BTS.",
    ]
    if backup_time_hours < 1.5:
        recommendations.append("L'autonomie obtenue reste inferieure a 1h30: revoir la batterie ou la charge critique.")
    if required_pv_power_wc > 10000:
        recommendations.append("La puissance PV depasse 10 kWc: prevoir une etude technique detaillee.")
    if required_battery_capacity_ah > 1200:
        recommendations.append("La capacite batterie est elevee: envisager une solution hybride solaire + groupe.")
    if available_surface_m2 > 0 and panel_surface_with_spacing_m2 > available_surface_m2:
        recommendations.append("La surface disponible est insuffisante: reduire les charges ou revoir l'implantation.")
    if load_shedding_required:
        recommendations.append("Un delestage des charges non critiques est necessaire pour tenir le secours PV.")
    if site.snel_available:
        recommendations.append("Comparer le cout d'exploitation PV avec le budget SNEL avant arbitrage final.")
    if site.generator_available:
        recommendations.append("Verifier la coherence entre la strategie PV, le groupe electrogene et la continute de service.")
    if feasibility_status.startswith("NON_FAISABLE"):
        recommendations.append("Le scenario actuel doit etre revu avant toute mise en oeuvre terrain.")
    if critical_power_watts == 0:
        recommendations.append("Ajouter au moins une puissance active critique pour rendre le dimensionnement exploitable.")
    if grounding_status == "MISE_A_LA_TERRE_NON_CONFORME":
        recommendations.append("La resistance de terre mesuree depasse la cible: ameliorer le reseau de terre avant mise en service.")
    if grounding_status == "MISE_A_LA_TERRE_A_VERIFIER":
        recommendations.append("Mesurer la resistance de terre sur site pour valider la protection des personnes et des BTS.")
    return recommendations


def _next_standard_rating(value: float) -> float:
    standards = [6, 10, 16, 20, 25, 32, 40, 50, 63, 80, 100, 125, 160, 200, 250]
    for rating in standards:
        if value <= rating:
            return float(rating)
    return float(ceil(value / 50) * 50)


def _recommended_cable_section(current_a: float, minimum_mm2: float) -> float:
    if current_a <= 0:
        return 0
    density_based = current_a / 6
    return round(max(minimum_mm2, ceil(density_based * 2) / 2), 2)


def _aggregate_equipment(equipment: list[Equipment]) -> dict[str, float]:
    total_power_watts = sum(item.power_watts * item.quantity for item in equipment)
    total_energy_wh = sum(item.power_watts * item.quantity * item.hours_per_day for item in equipment)
    critical_power_watts = sum(
        item.power_watts * item.quantity for item in equipment if item.is_critical
    )
    return {
        "total_power_watts": total_power_watts,
        "total_energy_wh": total_energy_wh,
        "critical_power_watts": critical_power_watts,
    }


def _aggregate_simple(simulation: Simulation) -> dict[str, float]:
    air_conditioner_critical_power = (
        simulation.air_conditioner_power_w if simulation.air_conditioner_is_critical else 0
    )
    critical_power_watts = (
        simulation.critical_active_power_w
        + simulation.other_critical_power_w
        + air_conditioner_critical_power
    )
    non_critical_power_watts = (
        simulation.other_non_critical_power_w
        + (0 if simulation.air_conditioner_is_critical else simulation.air_conditioner_power_w)
    )
    total_power_watts = critical_power_watts + non_critical_power_watts
    critical_energy_wh = critical_power_watts * simulation.backup_time_hours
    total_energy_wh = total_power_watts * simulation.backup_time_hours
    return {
        "total_power_watts": total_power_watts,
        "total_energy_wh": total_energy_wh,
        "critical_power_watts": critical_power_watts,
        "critical_energy_wh": critical_energy_wh,
    }


def _build_equipment_usage_plan(
    equipment: list[Equipment],
    *,
    inverter_power_watts: float,
    backup_time_hours: float,
    available_energy_wh: float,
    source: str,
    installed_panel_count: int,
    installed_battery_count: int,
    installed_inverter_power_watts: float,
) -> dict:
    if not equipment:
        return {
            "supported_equipment_count": 0,
            "supported_units_total": 0,
            "unsupported_equipment_count": 0,
            "supported_equipment": [],
            "unsupported_equipment": [],
        }

    ranked_equipment = sorted(
        equipment,
        key=lambda item: (
            0 if item.is_critical else 1,
            (item.power_watts * item.quantity),
            item.name.lower(),
        ),
    )
    remaining_power = max(inverter_power_watts, 0)
    remaining_energy = max(available_energy_wh, 0)
    supported_equipment: list[dict] = []
    unsupported_equipment: list[dict] = []
    analysis_rows: list[dict] = []

    for item in ranked_equipment:
        unit_power = item.power_watts
        unit_energy = item.power_watts * min(item.hours_per_day, backup_time_hours)
        max_by_power = int(remaining_power // unit_power) if unit_power > 0 else item.quantity
        max_by_energy = int(remaining_energy // unit_energy) if unit_energy > 0 else item.quantity
        supported_quantity = max(0, min(item.quantity, max_by_power, max_by_energy))

        payload = {
            "name": item.name,
            "category": item.category,
            "requested_quantity": item.quantity,
            "supported_quantity": supported_quantity,
            "unit_power_watts": round(item.power_watts, 2),
            "is_critical": item.is_critical,
        }
        status = "ALIMENTABLE" if supported_quantity >= item.quantity else "PARTIEL"
        if supported_quantity == 0:
            status = "NON_ALIMENTABLE"
        analysis_rows.append(
            {
                **payload,
                "unsupported_quantity": max(0, item.quantity - supported_quantity),
                "status": status,
                "reason": (
                    "OK"
                    if supported_quantity >= item.quantity
                    else (
                        "Puissance onduleur insuffisante"
                        if max_by_power < item.quantity
                        else "Autonomie batterie insuffisante"
                    )
                ),
            }
        )
        if supported_quantity > 0:
            supported_equipment.append(payload)
            remaining_power = max(0, remaining_power - supported_quantity * unit_power)
            remaining_energy = max(0, remaining_energy - supported_quantity * unit_energy)
        if supported_quantity < item.quantity:
            unsupported_equipment.append(
                {
                    **payload,
                    "unsupported_quantity": item.quantity - supported_quantity,
                    "reason": (
                        "Puissance onduleur insuffisante"
                        if max_by_power < item.quantity
                        else "Autonomie batterie insuffisante"
                    ),
                }
            )

    return {
        "source": source,
        "installed_panel_count": installed_panel_count,
        "installed_battery_count": installed_battery_count,
        "installed_inverter_power_watts": round(installed_inverter_power_watts, 2),
        "supported_equipment_count": len(supported_equipment),
        "supported_units_total": sum(item["supported_quantity"] for item in supported_equipment),
        "unsupported_equipment_count": len(unsupported_equipment),
        "supported_equipment": supported_equipment,
        "unsupported_equipment": unsupported_equipment,
        "analysis_rows": analysis_rows,
        "remaining_power_watts": round(remaining_power, 2),
        "remaining_energy_wh": round(remaining_energy, 2),
    }


def _inventory_status(required_value: float, available_value: float) -> str:
    if required_value <= 0:
        return "NON_REQUIS"
    if available_value >= required_value:
        return "DISPONIBLE"
    if available_value > 0:
        return "PARTIEL"
    return "MANQUANT"


def _build_component_inventory_plan(
    simulation: Simulation,
    *,
    required_panel_count: int,
    required_battery_count: int,
    required_inverter_power_watts: float,
    required_controller_current_a: float,
) -> dict:
    controller_total_current = (
        simulation.installed_controller_count * simulation.installed_controller_current_a
    )
    rows = [
        {
            "component": "Panneaux solaires",
            "required_label": f"{required_panel_count}",
            "available_label": f"{simulation.installed_panel_count}",
            "gap_label": f"{max(required_panel_count - simulation.installed_panel_count, 0)}",
            "status": _inventory_status(required_panel_count, simulation.installed_panel_count),
        },
        {
            "component": "Batteries",
            "required_label": f"{required_battery_count}",
            "available_label": f"{simulation.installed_battery_count}",
            "gap_label": f"{max(required_battery_count - simulation.installed_battery_count, 0)}",
            "status": _inventory_status(required_battery_count, simulation.installed_battery_count),
        },
        {
            "component": "Onduleur",
            "required_label": f"{round(required_inverter_power_watts, 2)} W",
            "available_label": f"{round(simulation.installed_inverter_power_watts, 2)} W",
            "gap_label": f"{round(max(required_inverter_power_watts - simulation.installed_inverter_power_watts, 0), 2)} W",
            "status": _inventory_status(required_inverter_power_watts, simulation.installed_inverter_power_watts),
        },
        {
            "component": "Regulateurs",
            "required_label": f"{round(required_controller_current_a, 2)} A",
            "available_label": f"{simulation.installed_controller_count} x {round(simulation.installed_controller_current_a, 2)} A = {round(controller_total_current, 2)} A",
            "gap_label": f"{round(max(required_controller_current_a - controller_total_current, 0), 2)} A",
            "status": _inventory_status(required_controller_current_a, controller_total_current),
        },
        {
            "component": "Parafoudre DC",
            "required_label": "1" if simulation.dc_spd_required else "0",
            "available_label": f"{simulation.installed_dc_spd_count}",
            "gap_label": f"{max((1 if simulation.dc_spd_required else 0) - simulation.installed_dc_spd_count, 0)}",
            "status": _inventory_status(1 if simulation.dc_spd_required else 0, simulation.installed_dc_spd_count),
        },
        {
            "component": "Parafoudre AC",
            "required_label": "1" if simulation.ac_spd_required else "0",
            "available_label": f"{simulation.installed_ac_spd_count}",
            "gap_label": f"{max((1 if simulation.ac_spd_required else 0) - simulation.installed_ac_spd_count, 0)}",
            "status": _inventory_status(1 if simulation.ac_spd_required else 0, simulation.installed_ac_spd_count),
        },
        {
            "component": "Kit de mise a la terre",
            "required_label": "1" if simulation.earthing_required else "0",
            "available_label": f"{simulation.installed_earthing_kit_count}",
            "gap_label": f"{max((1 if simulation.earthing_required else 0) - simulation.installed_earthing_kit_count, 0)}",
            "status": _inventory_status(1 if simulation.earthing_required else 0, simulation.installed_earthing_kit_count),
        },
    ]
    return {
        "rows": rows,
        "missing_components_count": len([row for row in rows if row["status"] in {"MANQUANT", "PARTIEL"}]),
    }


def calculate_simulation(site: Site, equipment: list[Equipment], simulation: Simulation) -> SimulationResult:
    use_simple_mode = simulation.critical_active_power_w > 0 or not equipment
    aggregates = _aggregate_simple(simulation) if use_simple_mode else _aggregate_equipment(equipment)

    total_power_watts = aggregates["total_power_watts"]
    critical_power_watts = aggregates["critical_power_watts"]
    non_critical_power_watts = max(total_power_watts - critical_power_watts, 0)
    daily_energy_wh = aggregates["total_energy_wh"]
    backup_time_target = simulation.backup_time_hours or site.target_backup_hours or 1.5
    critical_energy_wh = (
        aggregates["critical_energy_wh"]
        if use_simple_mode
        else critical_power_watts * backup_time_target
    )
    non_critical_energy_wh = max(daily_energy_wh - critical_energy_wh, 0) if use_simple_mode else max(
        sum(
            item.power_watts * item.quantity * min(item.hours_per_day, backup_time_target)
            for item in equipment
            if not item.is_critical
        ),
        0,
    )

    power_factor = simulation.power_factor if simulation.power_factor > 0 else 0.8
    apparent_power_va = critical_power_watts / power_factor if critical_power_watts > 0 else 0

    panel_unit_area_m2 = (
        simulation.panel_area_m2
        if simulation.panel_area_m2 > 0
        else simulation.panel_length_m * simulation.panel_width_m
    )
    available_surface_m2 = compute_usable_area(site)
    if site.available_area_m2 <= 0:
        site.available_area_m2 = available_surface_m2

    combined_efficiency = (
        max(site.system_efficiency, 0.05)
        * max(simulation.inverter_efficiency, 0.05)
        * max(simulation.controller_efficiency, 0.05)
        * max(simulation.battery_efficiency, 0.05)
    )
    loss_factor = 1 + simulation.cable_loss_factor + simulation.temperature_loss_factor + simulation.dust_loss_factor
    corrected_energy_wh = (
        (critical_energy_wh / combined_efficiency) * loss_factor * simulation.safety_factor
        if critical_energy_wh > 0
        else 0
    )

    required_battery_capacity_wh = corrected_energy_wh / max(simulation.battery_dod, 0.05) if corrected_energy_wh > 0 else 0
    required_battery_capacity_ah = required_battery_capacity_wh / max(site.system_voltage, 1) if required_battery_capacity_wh > 0 else 0
    number_of_batteries = (
        ceil(required_battery_capacity_ah / simulation.battery_capacity_ah)
        if simulation.battery_capacity_ah > 0 and required_battery_capacity_ah > 0
        else 0
    )

    battery_unit_energy_wh = simulation.battery_energy_kwh * 1000
    if battery_unit_energy_wh > 0 and required_battery_capacity_wh > 0:
        number_of_batteries = max(
            number_of_batteries,
            ceil(required_battery_capacity_wh / battery_unit_energy_wh),
        )

    usable_battery_energy_wh = number_of_batteries * battery_unit_energy_wh * simulation.battery_dod
    backup_time_hours = (
        usable_battery_energy_wh / critical_power_watts if critical_power_watts > 0 else 0
    )

    required_pv_power_wc = (
        (corrected_energy_wh / max(site.solar_irradiation_hours, 0.1)) * simulation.safety_factor
        if corrected_energy_wh > 0
        else 0
    )
    number_of_panels = (
        ceil(required_pv_power_wc / simulation.panel_power_watts)
        if simulation.panel_power_watts > 0 and required_pv_power_wc > 0
        else 0
    )
    panel_total_area_m2 = number_of_panels * panel_unit_area_m2
    panel_total_area_with_spacing_m2 = panel_total_area_m2 * simulation.panel_spacing_factor

    controller_current_a = (
        (required_pv_power_wc / max(site.system_voltage, 1)) * simulation.safety_factor
        if required_pv_power_wc > 0
        else 0
    )
    inverter_power_watts = apparent_power_va * simulation.safety_factor
    inverter_ac_current_a = inverter_power_watts / 230 if inverter_power_watts > 0 else 0

    dc_cable_section_mm2 = _recommended_cable_section(controller_current_a, 6)
    ac_cable_section_mm2 = _recommended_cable_section(inverter_ac_current_a, 4)
    earth_cable_section_mm2 = 16 if simulation.earthing_required else 0
    dc_breaker_rating_a = _next_standard_rating(controller_current_a * 1.25) if controller_current_a > 0 else 0
    ac_breaker_rating_a = _next_standard_rating(inverter_ac_current_a * 1.25) if inverter_ac_current_a > 0 else 0

    measured_earth = simulation.earthing_resistance_measured_ohm
    target_earth = simulation.earthing_resistance_target_ohm
    grounding_status = "MISE_A_LA_TERRE_NON_REQUISE"
    if simulation.earthing_required:
        if measured_earth <= 0:
            grounding_status = "MISE_A_LA_TERRE_A_VERIFIER"
        elif measured_earth <= target_earth:
            grounding_status = "MISE_A_LA_TERRE_CONFORME"
        else:
            grounding_status = "MISE_A_LA_TERRE_NON_CONFORME"

    total_energy_corrected_wh = (
        (daily_energy_wh / combined_efficiency) * loss_factor * simulation.safety_factor
        if daily_energy_wh > 0
        else 0
    )
    total_pv_required_wc = (
        (total_energy_corrected_wh / max(site.solar_irradiation_hours, 0.1)) * simulation.safety_factor
        if total_energy_corrected_wh > 0
        else 0
    )
    total_panel_count = (
        ceil(total_pv_required_wc / simulation.panel_power_watts)
        if simulation.panel_power_watts > 0 and total_pv_required_wc > 0
        else 0
    )
    total_surface_with_spacing = total_panel_count * panel_unit_area_m2 * simulation.panel_spacing_factor

    load_shedding_required = non_critical_power_watts > 0 and (
        total_surface_with_spacing > available_surface_m2
        or backup_time_hours >= backup_time_target
    )
    load_shedding_message = (
        "Les charges non critiques doivent etre delestees pour garantir le secours PV de 1h30."
        if load_shedding_required
        else "Aucun delestage des charges non critiques n'est necessaire."
    )

    surface_status = "SURFACE_OK"
    if available_surface_m2 <= 0:
        surface_status = "SURFACE_NON_RENSEIGNEE"
    elif panel_total_area_with_spacing_m2 > available_surface_m2:
        surface_status = "SURFACE_INSUFFISANTE"

    feasibility_status = "FAISABLE"
    if critical_power_watts <= 0 or critical_energy_wh <= 0:
        feasibility_status = "NON_FAISABLE_PAR_CAPACITE"
    elif surface_status == "SURFACE_INSUFFISANTE":
        feasibility_status = "NON_FAISABLE_PAR_SURFACE"
    elif backup_time_hours < backup_time_target:
        feasibility_status = "NON_FAISABLE_PAR_AUTONOMIE"
    elif load_shedding_required:
        feasibility_status = "FAISABLE_AVEC_DELESTAGE"

    if feasibility_status == "FAISABLE":
        dimensioning_state = "Dimensionnement faisable pour les charges critiques et le temps de secours programme."
    elif feasibility_status == "FAISABLE_AVEC_DELESTAGE":
        dimensioning_state = "Dimensionnement faisable si les charges non critiques sont delestees pendant la panne."
    elif feasibility_status == "NON_FAISABLE_PAR_SURFACE":
        dimensioning_state = "Dimensionnement non faisable avec la surface reellement exploitable du site."
    elif feasibility_status == "NON_FAISABLE_PAR_AUTONOMIE":
        dimensioning_state = "Dimensionnement non faisable pour atteindre l'autonomie de secours demandee."
    else:
        dimensioning_state = "Dimensionnement non faisable avec les donnees actuelles."

    warnings: list[str] = []
    if site.generator_failure_scenario:
        warnings.append("Le calcul est etabli pour un scenario de panne du groupe electrogene.")
    if not site.snel_available:
        warnings.append("La SNEL est consideree indisponible dans ce scenario de secours.")
    if site.available_area_m2 <= 0:
        warnings.append("La surface exploitable du site est nulle ou non renseignee.")
    if non_critical_power_watts > 0:
        warnings.append("Le systeme distingue bien les charges critiques et non critiques.")
    if simulation.lightning_protection_required:
        warnings.append("Une protection contre la foudre et les surtensions doit etre prevue pour le BTS et le champ PV.")
    if grounding_status == "MISE_A_LA_TERRE_A_VERIFIER":
        warnings.append("La resistance de terre n'est pas encore mesuree.")
    elif grounding_status == "MISE_A_LA_TERRE_NON_CONFORME":
        warnings.append("La resistance de terre mesuree n'est pas conforme a la cible.")

    pv_cost = number_of_panels * simulation.panel_unit_price
    battery_cost = number_of_batteries * simulation.battery_unit_price
    inverter_cost = simulation.inverter_price
    controller_cost = simulation.controller_price
    air_conditioner_cost = simulation.air_conditioner_price if simulation.air_conditioner_power_w > 0 else 0
    protection_cost = simulation.protection_price
    installation_cost = simulation.installation_price or simulation.labor_price
    accessories_cost = simulation.accessories_price
    maintenance_cost = simulation.maintenance_price
    total_investment_cost = (
        pv_cost
        + battery_cost
        + inverter_cost
        + controller_cost
        + air_conditioner_cost
        + protection_cost
        + accessories_cost
        + installation_cost
        + maintenance_cost
    )

    recommendations = build_recommendations(
        site,
        critical_power_watts,
        backup_time_hours,
        required_pv_power_wc,
        required_battery_capacity_ah,
        panel_total_area_with_spacing_m2,
        available_surface_m2,
        feasibility_status,
        load_shedding_required,
        grounding_status,
    )

    equipment_usage_plan = _build_equipment_usage_plan(
        equipment,
        inverter_power_watts=(
            simulation.installed_inverter_power_watts
            if simulation.installed_inverter_power_watts > 0
            else inverter_power_watts
        ),
        backup_time_hours=backup_time_target,
        available_energy_wh=(
            simulation.installed_battery_count * battery_unit_energy_wh * simulation.battery_dod
            if simulation.installed_battery_count > 0
            else critical_energy_wh
        ),
        source=(
            "entered_quantities"
            if simulation.installed_panel_count > 0 or simulation.installed_battery_count > 0
            else "recommended_dimensioning"
        ),
        installed_panel_count=simulation.installed_panel_count,
        installed_battery_count=simulation.installed_battery_count,
        installed_inverter_power_watts=(
            simulation.installed_inverter_power_watts
            if simulation.installed_inverter_power_watts > 0
            else inverter_power_watts
        ),
    )
    if equipment_usage_plan["unsupported_equipment_count"] > 0:
        recommendations.append(
            "Le plan d'usage recommande de limiter certains equipements ou leur quantite pendant le secours."
        )

    recommended_configuration = {
        "mode": "simple" if use_simple_mode else "advanced",
        "panel_type": simulation.panel_type,
        "number_of_panels": number_of_panels,
        "battery_type": simulation.battery_type,
        "number_of_batteries": number_of_batteries,
        "surface_required_m2": round(panel_total_area_with_spacing_m2, 2),
        "backup_time_target_hours": round(backup_time_target, 2),
        "inverter_power_va": round(inverter_power_watts, 2),
        "controller_current_a": round(controller_current_a, 2),
        "apparent_power_va": round(apparent_power_va, 2),
        "dc_cable_section_mm2": round(dc_cable_section_mm2, 2),
        "ac_cable_section_mm2": round(ac_cable_section_mm2, 2),
        "dc_breaker_rating_a": round(dc_breaker_rating_a, 2),
        "ac_breaker_rating_a": round(ac_breaker_rating_a, 2),
        "grounding_status": grounding_status,
        "equipment_usage_plan": equipment_usage_plan,
        "component_inventory_plan": _build_component_inventory_plan(
            simulation,
            required_panel_count=number_of_panels,
            required_battery_count=number_of_batteries,
            required_inverter_power_watts=inverter_power_watts,
            required_controller_current_a=controller_current_a,
        ),
    }

    return SimulationResult(
        simulation_id=simulation.id or 0,
        total_power_watts=round(total_power_watts, 2),
        critical_power_watts=round(critical_power_watts, 2),
        non_critical_power_watts=round(non_critical_power_watts, 2),
        apparent_power_va=round(apparent_power_va, 2),
        daily_energy_wh=round(daily_energy_wh, 2),
        critical_energy_wh=round(critical_energy_wh, 2),
        non_critical_energy_wh=round(non_critical_energy_wh, 2),
        corrected_energy_wh=round(corrected_energy_wh, 2),
        required_pv_power_wc=round(required_pv_power_wc, 2),
        number_of_panels=number_of_panels,
        panel_unit_area_m2=round(panel_unit_area_m2, 2),
        panel_total_area_m2=round(panel_total_area_m2, 2),
        panel_total_area_with_spacing_m2=round(panel_total_area_with_spacing_m2, 2),
        panel_surface_required_m2=round(panel_total_area_m2, 2),
        panel_surface_with_spacing_m2=round(panel_total_area_with_spacing_m2, 2),
        available_surface_m2=round(available_surface_m2, 2),
        surface_status=surface_status,
        required_battery_capacity_wh=round(required_battery_capacity_wh, 2),
        required_battery_capacity_ah=round(required_battery_capacity_ah, 2),
        number_of_batteries=number_of_batteries,
        backup_time_hours=round(backup_time_hours, 2),
        controller_current_a=round(controller_current_a, 2),
        inverter_power_watts=round(inverter_power_watts, 2),
        dc_cable_section_mm2=round(dc_cable_section_mm2, 2),
        ac_cable_section_mm2=round(ac_cable_section_mm2, 2),
        earth_cable_section_mm2=round(earth_cable_section_mm2, 2),
        dc_breaker_rating_a=round(dc_breaker_rating_a, 2),
        ac_breaker_rating_a=round(ac_breaker_rating_a, 2),
        dc_spd_required=simulation.dc_spd_required,
        ac_spd_required=simulation.ac_spd_required,
        lightning_protection_required=simulation.lightning_protection_required,
        earthing_required=simulation.earthing_required,
        recommended_earthing_resistance_ohm=round(target_earth, 2),
        measured_earthing_resistance_ohm=round(measured_earth, 2),
        grounding_status=grounding_status,
        feasibility_status=feasibility_status,
        dimensioning_state=dimensioning_state,
        load_shedding_required=load_shedding_required,
        load_shedding_message=load_shedding_message,
        warnings_json=json.dumps(warnings),
        recommended_configuration_json=json.dumps(recommended_configuration),
        pv_cost=round(pv_cost, 2),
        battery_cost=round(battery_cost, 2),
        inverter_cost=round(inverter_cost, 2),
        controller_cost=round(controller_cost, 2),
        air_conditioner_cost=round(air_conditioner_cost, 2),
        protection_cost=round(protection_cost, 2),
        installation_cost=round(installation_cost, 2),
        accessories_cost=round(accessories_cost, 2),
        maintenance_cost=round(maintenance_cost, 2),
        total_investment_cost=round(total_investment_cost, 2),
        snel_operating_cost=round(simulation.snel_operating_cost, 2),
        generator_operating_cost=round(simulation.generator_operating_cost, 2),
        total_cost=round(total_investment_cost, 2),
        recommendations="\n".join(recommendations),
    )
