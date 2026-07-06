const legacyApiUrl = 'https://greensitepvdesignerteam750.onrender.com'
const requestedApiUrl = import.meta.env.VITE_API_BASE_URL?.trim()
const configuredApiUrl =
  import.meta.env.PROD && requestedApiUrl === legacyApiUrl ? undefined : requestedApiUrl
const defaultApiUrl = import.meta.env.DEV
  ? 'http://localhost:8000'
  : 'https://greensitepvdesignerteam750s.onrender.com'

export const API_BASE_URL = (configuredApiUrl || defaultApiUrl).replace(/\/+$/, '')
