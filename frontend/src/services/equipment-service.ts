import { apiRequest } from '../lib/api'
import type { EquipmentItem } from '../types/domain'

export type EquipmentCreatePayload = {
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
}

export function listEquipment(token: string, siteId: number) {
  return apiRequest<EquipmentItem[]>(`/sites/${siteId}/equipment`, { token })
}

export function createEquipment(token: string, siteId: number, payload: EquipmentCreatePayload) {
  return apiRequest<EquipmentItem>(`/sites/${siteId}/equipment`, {
    method: 'POST',
    token,
    body: payload,
  })
}

export function updateEquipment(
  token: string,
  equipmentId: number,
  payload: Partial<EquipmentCreatePayload>,
) {
  return apiRequest<EquipmentItem>(`/equipment/${equipmentId}`, {
    method: 'PUT',
    token,
    body: payload,
  })
}

export function deleteEquipment(token: string, equipmentId: number) {
  return apiRequest<void>(`/equipment/${equipmentId}`, {
    method: 'DELETE',
    token,
  })
}
