import {
  createContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { apiRequest } from '../lib/api'
import type { AuthTokenResponse, AuthUser, LoginPayload } from '../types/auth'

type AuthContextValue = {
  user: AuthUser | null
  token: string | null
  isAuthenticated: boolean
  login: (payload: LoginPayload) => Promise<void>
  logout: () => void
}

const STORAGE_KEY = 'greensite-auth'

type StoredAuth = {
  token: string | null
  user: AuthUser | null
}

export const AuthContext = createContext<AuthContextValue | null>(null)

function readStoredAuth(): StoredAuth {
  const raw = window.localStorage.getItem(STORAGE_KEY)
  if (!raw) {
    return { token: null, user: null }
  }

  try {
    return JSON.parse(raw) as StoredAuth
  } catch {
    return { token: null, user: null }
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(null)
  const [user, setUser] = useState<AuthUser | null>(null)

  useEffect(() => {
    const stored = readStoredAuth()
    setToken(stored.token)
    setUser(stored.user)
  }, [])

  useEffect(() => {
    window.localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        token,
        user,
      }),
    )
  }, [token, user])

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      token,
      isAuthenticated: Boolean(user),
      async login(payload) {
        const result = await apiRequest<AuthTokenResponse>('/auth/login', {
          method: 'POST',
          body: payload,
        })
        setToken(result.access_token)
        setUser(result.user)
      },
      logout() {
        setToken(null)
        setUser(null)
      },
    }),
    [token, user],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
