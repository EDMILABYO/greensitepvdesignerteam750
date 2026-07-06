import { apiRequest } from '../lib/api'
import type { SiteSummary } from '../types/domain'

export type SiteCreatePayload = {
  name: string
  city: string
  country: string
  site_type: string
  description: string
  latitude: number
  longitude: number
  operating_hours_per_day: number
  autonomy_days: number
  target_backup_hours: number
  solar_irradiation_hours: number
  system_efficiency: number
  system_voltage: number
  total_area_m2: number
  tower_area_m2: number
  rack_area_m2: number
  generator_area_m2: number
  other_blocked_area_m2: number
  available_area_m2: number
  usable_area_ratio: number
  layout_length_m: number
  layout_width_m: number
  snel_available: boolean
  generator_available: boolean
  generator_failure_scenario: boolean
}

export function listSites(token: string) {
  return apiRequest<SiteSummary[]>('/sites', { token })
}

export function createSite(token: string, payload: SiteCreatePayload) {
  return apiRequest<SiteSummary>('/sites', {
    method: 'POST',
    token,
    body: payload,
  })
}

export function updateSite(token: string, siteId: number, payload: SiteCreatePayload) {
  return apiRequest<SiteSummary>(`/sites/${siteId}`, {
    method: 'PUT',
    token,
    body: payload,
  })
}
