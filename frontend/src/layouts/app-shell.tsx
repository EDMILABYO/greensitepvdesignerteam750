import { useState } from 'react'
import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/use-auth'
import { canManageSimulations, canManageUsers } from '../lib/permissions'

function MenuIcon({
  kind,
}: {
  kind: 'dashboard' | 'sites' | 'simulations' | 'new' | 'reports' | 'users'
}) {
  if (kind === 'dashboard') {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path
          d="M4 11.5 12 5l8 6.5V20a1 1 0 0 1-1 1h-4.5v-5h-5v5H5a1 1 0 0 1-1-1z"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    )
  }

  if (kind === 'sites') {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path
          d="M12 21s6-5.5 6-10a6 6 0 1 0-12 0c0 4.5 6 10 6 10Z"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinejoin="round"
        />
        <circle cx="12" cy="11" r="2.3" fill="none" stroke="currentColor" strokeWidth="1.8" />
      </svg>
    )
  }

  if (kind === 'simulations') {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <rect
          x="4"
          y="5"
          width="16"
          height="14"
          rx="3"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
        />
        <path
          d="M8 14l2.5-2.5 2 2 3.5-4"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    )
  }

  if (kind === 'new') {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <circle cx="12" cy="12" r="8.5" fill="none" stroke="currentColor" strokeWidth="1.8" />
        <path
          d="M12 8v8M8 12h8"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
        />
      </svg>
    )
  }

  if (kind === 'reports') {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path
          d="M8 4h6l4 4v11a1 1 0 0 1-1 1H8a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Z"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinejoin="round"
        />
        <path d="M14 4v4h4M9 12h6M9 15h6" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
      </svg>
    )
  }

  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="M16.5 19a4.5 4.5 0 1 0 0-9 4.5 4.5 0 0 0 0 9ZM7.5 17.5A3.5 3.5 0 1 0 7.5 10a3.5 3.5 0 0 0 0 7.5Z"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M2.5 20c.8-2.6 2.8-3.9 5-3.9 1.3 0 2.4.4 3.2 1.1M12.3 19.7c1-2 2.9-3.2 5.2-3.2 2 0 3.7.9 4.5 2.5"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
    </svg>
  )
}

type NavigationIcon = 'dashboard' | 'sites' | 'simulations' | 'new' | 'reports' | 'users'

type NavigationItem = {
  to: string
  label: string
  icon: NavigationIcon
}

const navigationItems: NavigationItem[] = [
  { to: '/', label: 'Dashboard', icon: 'dashboard' as const },
  { to: '/sites', label: 'Sites', icon: 'sites' as const },
  { to: '/simulations', label: 'Simulations', icon: 'simulations' as const },
  { to: '/simulations/new', label: 'Nouveau calcul', icon: 'new' as const },
  { to: '/reports', label: 'Rapports', icon: 'reports' as const },
]

export function AppShell() {
  const { user, logout } = useAuth()
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const navigation = navigationItems
    .filter((item) => item.to !== '/simulations/new' || canManageSimulations(user?.role))
    .concat(
      canManageUsers(user?.role)
        ? [{ to: '/users', label: 'Utilisateurs', icon: 'users' as const }]
        : [],
    )

  return (
    <div className="app-shell">
      <aside className={`sidebar ${isMobileMenuOpen ? 'sidebar--open' : ''}`}>
        <div className="brand">
          <span className="brand__kicker">HAYATCOM</span>
          <strong>HAYAT-Solar Sizer</strong>
          <p>Plateforme de dimensionnement photovoltaique pour sites telecom.</p>
        </div>

        <nav id="mobile-navigation" className="sidebar__nav" aria-label="Navigation principale">
          {navigation.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              onClick={() => setIsMobileMenuOpen(false)}
              className={({ isActive }) =>
                isActive ? 'sidebar__link sidebar__link--active' : 'sidebar__link'
              }
            >
              <span className="sidebar__link-icon">
                <MenuIcon kind={item.icon} />
              </span>
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div className="topbar__title-block">
            <button
              className="mobile-menu-toggle"
              type="button"
              aria-label={isMobileMenuOpen ? 'Fermer le menu' : 'Ouvrir le menu'}
              aria-expanded={isMobileMenuOpen}
              aria-controls="mobile-navigation"
              onClick={() => setIsMobileMenuOpen((open) => !open)}
            >
              <span />
              <span />
              <span />
            </button>
            <span className="topbar__eyebrow">Tableau de bord</span>
            <h1>HAYAT-Solar Sizer</h1>
          </div>
          <div className="topbar__actions">
            <span className="topbar__identity">{user?.full_name}</span>
            <button className="topbar__logout" type="button" onClick={logout}>
              Deconnexion
            </button>
          </div>
        </header>

        {isMobileMenuOpen ? (
          <button
            className="mobile-menu-backdrop"
            type="button"
            aria-label="Fermer le menu"
            onClick={() => setIsMobileMenuOpen(false)}
          />
        ) : null}

        <div className="content-scroll">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
