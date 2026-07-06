import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/use-auth'

function MailIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M4 6h16a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2Zm0 2v.2l8 5.2 8-5.2V8H4Zm16 8V10.6l-7.46 4.84a1 1 0 0 1-1.08 0L4 10.6V16h16Z"
        fill="currentColor"
      />
    </svg>
  )
}

function LockIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M12 2a5 5 0 0 1 5 5v2h1a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2h1V7a5 5 0 0 1 5-5Zm6 9H6v9h12v-9Zm-6 2a2.5 2.5 0 0 1 1 4.79V19h-2v-1.21A2.5 2.5 0 0 1 12 13Zm0-9a3 3 0 0 0-3 3v2h6V7a3 3 0 0 0-3-3Z"
        fill="currentColor"
      />
    </svg>
  )
}

function EyeIcon({ open }: { open: boolean }) {
  return open ? (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M12 5c4.96 0 9.15 3.03 10.8 7.3a.98.98 0 0 1 0 .7C21.15 17.27 16.96 20.3 12 20.3S2.85 17.27 1.2 13a.98.98 0 0 1 0-.7C2.85 8.03 7.04 5 12 5Zm0 2C8.08 7 4.7 9.3 3.23 12c1.47 2.7 4.85 5 8.77 5s7.3-2.3 8.77-5C19.3 9.3 15.92 7 12 7Zm0 2.2a2.8 2.8 0 1 1 0 5.6 2.8 2.8 0 0 1 0-5.6Z"
        fill="currentColor"
      />
    </svg>
  ) : (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="m3.28 2 18.72 18.72-1.41 1.41-3.02-3.02A11.42 11.42 0 0 1 12 20.3c-4.96 0-9.15-3.03-10.8-7.3a.98.98 0 0 1 0-.7A12.1 12.1 0 0 1 6.1 6.63L1.86 2.4 3.28 2Zm4.31 6.55A9.8 9.8 0 0 0 3.23 12c1.47 2.7 4.85 5 8.77 5 1.43 0 2.8-.3 4.03-.84l-2.17-2.17a2.8 2.8 0 0 1-3.85-3.85L7.59 8.55ZM12 5c4.96 0 9.15 3.03 10.8 7.3a.98.98 0 0 1 0 .7 12.1 12.1 0 0 1-3.66 4.78l-1.43-1.43A9.78 9.78 0 0 0 20.77 12C19.3 9.3 15.92 7 12 7c-.63 0-1.24.06-1.82.18L8.5 5.5C9.63 5.18 10.8 5 12 5Z"
        fill="currentColor"
      />
    </svg>
  )
}

function ShieldIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M12 2.5 19 5v6.2c0 4.4-2.7 8.4-7 10.3-4.3-1.9-7-5.9-7-10.3V5l7-2.5Zm0 2.1L7 6.4v4.8c0 3.4 1.9 6.4 5 8 3.1-1.6 5-4.6 5-8V6.4l-5-1.8Zm2.1 4.6 1.4 1.4-4.1 4.2-2.8-2.8L10 10.6l1.4 1.4 2.7-2.8Z"
        fill="currentColor"
      />
    </svg>
  )
}

function ArrowIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M13.2 5.8 19.4 12l-6.2 6.2-1.4-1.4 3.8-3.8H4.5v-2h11.1l-3.8-3.8 1.4-1.4Z"
        fill="currentColor"
      />
    </svg>
  )
}

export function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [rememberMe, setRememberMe] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const redirectTo = (location.state as { from?: string } | null)?.from || '/'

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setLoading(true)
    setError(null)
    try {
      await login({ email, password })
      navigate(redirectTo, { replace: true })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Connexion impossible.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <section className="auth-page">
      <div className="auth-shell">
        <aside className="auth-showcase">
          <div className="auth-showcase__image-wrap">
            <img
              src="/login-hero-reference.png"
              alt="Equipe technique sur installation solaire"
              className="auth-showcase__image"
            />
            <div className="auth-showcase__overlay" />
          </div>
          <div className="auth-showcase__card">
            <div className="auth-showcase__badge">
              <img src="/login-logo-reference.png" alt="" className="auth-showcase__badge-image" />
            </div>
            <h2>Dimensionnez l&apos;avenir avec precision.</h2>
            <p>
              HAYAT-Solar Sizer vous accompagne dans la conception optimale de vos installations
              photovoltaiques de secours.
            </p>
            <div className="auth-showcase__progress" aria-hidden="true">
              <span className="is-active" />
              <span />
              <span />
            </div>
          </div>
        </aside>

        <div className="auth-card auth-card--wide">
          <div className="auth-brand">
            <img src="/login-logo-reference.png" alt="HAYAT Solar Solutions" className="auth-brand__image" />
          </div>

          <span className="section-title__eyebrow">Connexion</span>
          <h1>HAYAT-Solar Sizer</h1>
          <p className="auth-card__intro">Connecte-toi a l&apos;application avec ton compte utilisateur.</p>

          <form className="auth-form auth-form--premium" onSubmit={handleSubmit} autoComplete="off">
            <label>
              <span>Email</span>
              <div className="auth-input">
                <span className="auth-input__icon">
                  <MailIcon />
                </span>
                <input
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  type="email"
                  placeholder="exemple@domaine.com"
                  autoComplete="off"
                  required
                />
              </div>
            </label>

            <label>
              <span>Mot de passe</span>
              <div className="auth-input">
                <span className="auth-input__icon">
                  <LockIcon />
                </span>
                <input
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  type={showPassword ? 'text' : 'password'}
                  placeholder="........"
                  autoComplete="new-password"
                  required
                />
                <button
                  className="auth-input__toggle"
                  type="button"
                  onClick={() => setShowPassword((current) => !current)}
                  aria-label={showPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'}
                >
                  <EyeIcon open={showPassword} />
                </button>
              </div>
            </label>

            <div className="auth-form__row">
              <label className="auth-check">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                />
                <span>Se souvenir de moi</span>
              </label>
              <button className="auth-link" type="button">
                Mot de passe oublie ?
              </button>
            </div>

            {error ? <p className="form-error">{error}</p> : null}

            <div className="auth-actions">
              <button className="button-link button-link--solid auth-submit" type="submit" disabled={loading}>
                {loading ? 'Connexion...' : 'Se connecter'}
                <span className="auth-submit__icon" aria-hidden="true">
                  <ArrowIcon />
                </span>
              </button>
            </div>

            <p className="auth-security">
              <span className="auth-security__icon">
                <ShieldIcon />
              </span>
              Vos donnees sont securisees et confidentielles.
            </p>
          </form>
        </div>
      </div>
    </section>
  )
}
