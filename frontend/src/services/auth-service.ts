import { apiRequest } from '../lib/api'
import type { AuthTokenResponse, LoginPayload } from '../types/auth'

export function loginRequest(payload: LoginPayload) {
  return apiRequest<AuthTokenResponse>('/auth/login', {
    method: 'POST',
    body: payload,
  })
}
