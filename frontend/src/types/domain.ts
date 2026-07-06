export type FeasibilityStatus =
  | 'FAISABLE'
  | 'FAISABLE_AVEC_DELESTAGE'
  | 'NON_FAISABLE_PAR_SURFACE'
  | 'NON_FAISABLE_PAR_AUTONOMIE'
  | 'NON_FAISABLE_PAR_CAPACITE'

export type SiteSummary = {
  id: number
  name: string
  city: string
  country: string
  site_type: string
  description?: string
  latitude?: number
  longitude?: number
  operating_hours_per_day?: number
  autonomy_days?: number
  total_area_m2: number
  tower_area_m2: number
  rack_area_m2: number
  generator_area_m2: number
  other_blocked_area_m2: number
  available_area_m2: number
  usable_area_ratio?: number
  layout_length_m?: number
  layout_width_m?: number
  target_backup_hours: number
  solar_irradiation_hours?: number
  system_efficiency?: number
  system_voltage?: number
  snel_available?: boolean
  generator_available?: boolean
  generator_failure_scenario?: boolean
}

export type SimulationSummary = {
  id: number
  site_id: number
  created_at: string
  panel_power_watts?: number
  battery_capacity_ah?: number
  user_id?: number
  result?: {
    required_pv_power_wc: number
    number_of_panels: number
    backup_time_hours: number
    feasibility_status: FeasibilityStatus
    dimensioning_state: string
    panel_surface_with_spacing_m2?: number
    available_surface_m2?: number
    load_shedding_required?: boolean
    load_shedding_message?: string
    total_cost?: number
  } | null
}

export type EquipmentItem = {
  id: number
  site_id: number
  name: string
  category: string
  power_watts: number
  quantity: number
  hours_per_day: number
  is_critical: boolean
  notes: string
  position_x_m: number
  position_y_m: number
  footprint_length_m: number
  footprint_width_m: number
  created_at: string
  updated_at: string
}

export type SimulationResultDetail = {
  id: number
  simulation_id: number
  total_power_watts: number
  critical_power_watts: number
  non_critical_power_watts: number
  apparent_power_va: number
  daily_energy_wh: number
  critical_energy_wh: number
  non_critical_energy_wh: number
  corrected_energy_wh: number
  required_pv_power_wc: number
  number_of_panels: number
  panel_unit_area_m2: number
  panel_total_area_m2: number
  panel_total_area_with_spacing_m2: number
  panel_surface_required_m2: number
  panel_surface_with_spacing_m2: number
  available_surface_m2: number
  surface_status: string
  required_battery_capacity_wh: number
  required_battery_capacity_ah: number
  number_of_batteries: number
  backup_time_hours: number
  controller_current_a: number
  inverter_power_watts: number
  dc_cable_section_mm2: number
  ac_cable_section_mm2: number
  earth_cable_section_mm2: number
  dc_breaker_rating_a: number
  ac_breaker_rating_a: number
  dc_spd_required: boolean
  ac_spd_required: boolean
  lightning_protection_required: boolean
  earthing_required: boolean
  recommended_earthing_resistance_ohm: number
  measured_earthing_resistance_ohm: number
  grounding_status: string
  feasibility_status: FeasibilityStatus
  dimensioning_state: string
  load_shedding_required: boolean
  load_shedding_message: string
  warnings_json: string
  recommended_configuration_json: string
  pv_cost: number
  battery_cost: number
  inverter_cost: number
  controller_cost: number
  air_conditioner_cost: number
  protection_cost: number
  installation_cost: number
  accessories_cost: number
  maintenance_cost: number
  total_investment_cost: number
  snel_operating_cost: number
  generator_operating_cost: number
  total_cost: number
  recommendations: string
  created_at: string
}

export type SimulationDetail = {
  id: number
  user_id: number
  site_id: number
  created_at: string
  critical_active_power_w: number
  backup_time_hours: number
  power_factor: number
  air_conditioner_power_w: number
  air_conditioner_is_critical: boolean
  other_critical_power_w: number
  other_non_critical_power_w: number
  panel_power_watts: number
  panel_type: string
  panel_length_m: number
  panel_width_m: number
  panel_area_m2: number
  panel_spacing_factor: number
  installed_panel_count: number
  battery_capacity_ah: number
  battery_voltage: number
  battery_type: string
  battery_energy_kwh: number
  installed_battery_count: number
  installed_inverter_power_watts: number
  installed_controller_count: number
  installed_controller_current_a: number
  installed_dc_spd_count: number
  installed_ac_spd_count: number
  installed_earthing_kit_count: number
  battery_dod: number
  battery_efficiency: number
  controller_efficiency: number
  inverter_efficiency: number
  cable_loss_factor: number
  dc_cable_length_m: number
  ac_cable_length_m: number
  dc_voltage_drop_limit_percent: number
  ac_voltage_drop_limit_percent: number
  temperature_loss_factor: number
  dust_loss_factor: number
  safety_factor: number
  lightning_protection_required: boolean
  dc_spd_required: boolean
  ac_spd_required: boolean
  earthing_required: boolean
  earthing_resistance_target_ohm: number
  earthing_resistance_measured_ohm: number
  panel_unit_price: number
  battery_unit_price: number
  inverter_price: number
  controller_price: number
  air_conditioner_price: number
  accessories_price: number
  protection_price: number
  installation_price: number
  labor_price: number
  maintenance_price: number
  snel_operating_cost: number
  generator_operating_cost: number
  result: SimulationResultDetail | null
}

export type DashboardSummary = {
  total_simulations: number
  last_simulation: string | null
  average_pv_power_wc: number
  average_battery_capacity_ah: number
}

export type SimulationReport = {
  academic_notice: string
  site: SiteSummary
  equipment: EquipmentItem[]
  simulation: Omit<SimulationDetail, 'result'>
  result: SimulationResultDetail | null
  assumptions: string[]
}
