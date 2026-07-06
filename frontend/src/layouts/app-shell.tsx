import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../hooks/use-auth'
import { canManageSimulations, canManageUsers } from '../lib/permissions'

const navigationItems = [
  { to: '/', label: 'Dashboard' },
  { to: '/sites', label: 'Sites' },
  { to: '/simulations', label: 'Simulations' },
  { to: '/simulations/new', label: 'Nouveau calcul' },
  { to: '/reports', label: 'Rapports' },
]

export function AppShell() {
  const { user, logout } = useAuth()
  const navigation = navigationItems
    .filter((item) => item.to !== '/simulations/new' || canManageSimulations(user?.role))
    .concat(canManageUsers(user?.role) ? [{ to: '/users', label: 'Utilisateurs' }] : [])

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <span className="brand__kicker">HAYATCOM</span>
          <strong>HAYAT-Solar Sizer</strong>
          <p>Plateforme de dimensionnement photovoltaique pour sites telecom.</p>
        </div>

        <nav className="sidebar__nav" aria-label="Navigation principale">
          {navigation.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                isActive ? 'sidebar__link sidebar__link--active' : 'sidebar__link'
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div className="topbar__title-block">
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

        <div className="content-scroll">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
