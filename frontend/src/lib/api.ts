import { API_BASE_URL } from '../config/env'

export type ApiMethod = 'GET' | 'POST' | 'PUT' | 'DELETE'

type RequestOptions = {
  method?: ApiMethod
  token?: string | null
  body?: unknown
}

export async function apiRequest<T>(
  path: string,
  { method = 'GET', token, body }: RequestOptions = {},
): Promise<T> {
  let response: Response
  try {
    response = await fetch(`${API_BASE_URL}${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    })
  } catch {
    throw new Error(
      'Impossible de joindre le serveur. Verifiez votre connexion puis reessayez.',
    )
  }

  if (!response.ok) {
    const message = await response.text()
    throw new Error(message || 'Echec de communication avec le serveur.')
  }

  if (response.status === 204) {
    return undefined as T
  }

  const contentType = response.headers.get('content-type') ?? ''
  if (!contentType.includes('application/json')) {
    const text = await response.text()
    return text as T
  }

  const raw = await response.text()
  if (!raw.trim()) {
    return undefined as T
  }

  return JSON.parse(raw) as T
}
