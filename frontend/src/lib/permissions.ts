import type { UserRole } from '../types/auth'

export function canManageUsers(role?: UserRole | null) {
  return role === 'admin'
}

export function canViewAllRecords(role?: UserRole | null) {
  return role === 'admin' || role === 'manager'
}

export function canManageSiteData(role?: UserRole | null) {
  return role === 'admin' || role === 'engineer' || role === 'operator' || role === 'student'
}

export function canManageSimulations(role?: UserRole | null) {
  return role === 'admin' || role === 'engineer' || role === 'student'
}
