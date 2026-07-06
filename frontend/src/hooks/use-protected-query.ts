import { useEffect, useRef, useState } from 'react'
import { useAuth } from './use-auth'

type UseProtectedQueryOptions<T> = {
  fallbackData: T
  queryKey: string
  request: (token: string) => Promise<T>
}

export function useProtectedQuery<T>({
  fallbackData,
  queryKey,
  request,
}: UseProtectedQueryOptions<T>) {
  const { token, isAuthenticated } = useAuth()
  const [data, setData] = useState<T>(fallbackData)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const requestRef = useRef(request)
  const fallbackRef = useRef(fallbackData)

  requestRef.current = request
  fallbackRef.current = fallbackData

  useEffect(() => {
    let active = true

    async function load() {
      if (!isAuthenticated || !token) {
        setData(fallbackRef.current)
        return
      }

      setLoading(true)
      setError(null)
      try {
        const result = await requestRef.current(token)
        if (active) {
          setData(result)
        }
      } catch (err) {
        if (active) {
          setError(err instanceof Error ? err.message : 'Erreur de chargement')
          setData(fallbackRef.current)
        }
      } finally {
        if (active) {
          setLoading(false)
        }
      }
    }

    void load()

    return () => {
      active = false
    }
  }, [isAuthenticated, queryKey, token])

  return { data, loading, error, setData }
}
