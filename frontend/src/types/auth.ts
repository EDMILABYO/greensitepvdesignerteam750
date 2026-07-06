export type UserRole =
  | 'admin'
  | 'manager'
  | 'engineer'
  | 'operator'
  | 'observer'
  | 'student'

export const ROLE_OPTIONS: Array<{ value: UserRole; label: string }> = [
  { value: 'admin', label: 'Administrateur' },
  { value: 'manager', label: 'Manager' },
  { value: 'engineer', label: 'Ingenieur' },
  { value: 'operator', label: 'Operateur' },
  { value: 'observer', label: 'Observateur' },
  { value: 'student', label: 'Etudiant' },
]

export type AuthUser = {
  id: number
  full_name: string
  email: string
  role: UserRole
  created_at: string
}

export type AuthTokenResponse = {
  access_token: string
  token_type: string
  user: AuthUser
}

export type LoginPayload = {
  email: string
  password: string
}

export type AdminUserPayload = {
  full_name: string
  email: string
  password: string
  role: UserRole
}

export type AdminUserUpdatePayload = {
  full_name?: string
  email?: string
  password?: string
  role?: UserRole
}
