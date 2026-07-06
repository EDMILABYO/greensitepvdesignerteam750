const configuredApiUrl = import.meta.env.VITE_API_BASE_URL?.trim()
const defaultApiUrl = import.meta.env.DEV
  ? 'http://localhost:8000'
  : 'https://greensitepvdesignerteam750.onrender.com'

export const API_BASE_URL = (configuredApiUrl || defaultApiUrl).replace(/\/+$/, '')
