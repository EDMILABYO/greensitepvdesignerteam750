import { API_BASE_URL } from '../config/env'
import { apiRequest } from '../lib/api'
import type {
  DashboardSummary,
  SimulationDetail,
  SimulationReport,
  SimulationResultDetail,
  SimulationSummary,
} from '../types/domain'

export type SimulationCreatePayload = {
  site_id: number
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
}

export function listSimulations(token: string) {
  return apiRequest<SimulationSummary[]>('/simulations', { token })
}

export function getDashboardSummary(token: string) {
  return apiRequest<DashboardSummary>('/simulations/dashboard/summary', { token })
}

export function createSimulation(token: string, payload: SimulationCreatePayload) {
  return apiRequest<SimulationSummary>('/simulations', {
    method: 'POST',
    token,
    body: payload,
  })
}

export function updateSimulation(
  token: string,
  simulationId: number,
  payload: SimulationCreatePayload,
) {
  return apiRequest<SimulationDetail>(`/simulations/${simulationId}`, {
    method: 'PUT',
    token,
    body: payload,
  })
}

export function getSimulation(token: string, simulationId: number) {
  return apiRequest<SimulationDetail>(`/simulations/${simulationId}`, { token })
}

export function calculateSimulation(token: string, simulationId: number) {
  return apiRequest<SimulationResultDetail>(`/simulations/${simulationId}/calculate`, {
    method: 'POST',
    token,
  })
}

export function deleteSimulation(token: string, simulationId: number) {
  return apiRequest<void>(`/simulations/${simulationId}`, {
    method: 'DELETE',
    token,
  })
}

export function getSimulationReport(token: string, simulationId: number) {
  return apiRequest<SimulationReport>(`/simulations/${simulationId}/report`, { token })
}

export async function downloadSimulationReportPdf(token: string, simulationId: number) {
  const response = await fetch(`${API_BASE_URL}/simulations/${simulationId}/report/pdf`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  })

  if (!response.ok) {
    const message = await response.text()
    throw new Error(message || 'Echec du telechargement du PDF.')
  }

  return response.blob()
}
