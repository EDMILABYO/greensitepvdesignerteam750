import { apiRequest } from '../lib/api'
import type { AdminUserPayload, AdminUserUpdatePayload, AuthUser } from '../types/auth'

export function listAdminUsers(token: string) {
  return apiRequest<AuthUser[]>('/admin/users', { token })
}

export function createAdminUser(token: string, payload: AdminUserPayload) {
  return apiRequest<AuthUser>('/admin/users', {
    method: 'POST',
    token,
    body: payload,
  })
}

export function updateAdminUser(token: string, userId: number, payload: AdminUserUpdatePayload) {
  return apiRequest<AuthUser>(`/admin/users/${userId}`, {
    method: 'PUT',
    token,
    body: payload,
  })
}

export async function deleteAdminUser(token: string, userId: number) {
  await apiRequest<undefined>(`/admin/users/${userId}`, {
    method: 'DELETE',
    token,
  })
}
