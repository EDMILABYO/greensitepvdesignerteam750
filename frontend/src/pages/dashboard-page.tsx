import { Link } from 'react-router-dom'
import { useAuth } from '../hooks/use-auth'
import { useProtectedQuery } from '../hooks/use-protected-query'
import { canManageUsers } from '../lib/permissions'
import { getDashboardSummary, listSimulations } from '../services/simulation-service'
import { listSites } from '../services/site-service'
import type { FeasibilityStatus } from '../types/domain'

const emptyDashboard = {
  total_simulations: 0,
  last_simulation: null,
  average_pv_power_wc: 0,
  average_battery_capacity_ah: 0,
}

const statusLabels: Record<FeasibilityStatus, string> = {
  FAISABLE: 'Faisable',
  FAISABLE_AVEC_DELESTAGE: 'A revoir',
  NON_FAISABLE_PAR_SURFACE: 'Non faisable',
  NON_FAISABLE_PAR_AUTONOMIE: 'Non faisable',
  NON_FAISABLE_PAR_CAPACITE: 'Non faisable',
}

const statusToneClass: Record<FeasibilityStatus, string> = {
  FAISABLE: 'is-feasible',
  FAISABLE_AVEC_DELESTAGE: 'is-warning',
  NON_FAISABLE_PAR_SURFACE: 'is-danger',
  NON_FAISABLE_PAR_AUTONOMIE: 'is-danger',
  NON_FAISABLE_PAR_CAPACITE: 'is-danger',
}

function formatCompact(value: number, digits = 0) {
  return value.toLocaleString('en-US', {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  })
}

function formatDateTime(value: string) {
  return new Date(value).toLocaleString('fr-FR', {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function getSimulationTitle(simulationId: number, siteName?: string) {
  return siteName ? `${siteName}` : `Simulation #${simulationId}`
}

function DashboardIcon({ kind }: { kind: 'solar' | 'battery' | 'simulation' | 'feasibility' }) {
  if (kind === 'solar') {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path
          d="M12 2v3M4.9 4.9l2.1 2.1M2 12h3M4.9 19.1L7 17M12 19v3M17 17l2.1 2.1M19 12h3M17 7l2.1-2.1"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
        />
        <circle cx="12" cy="12" r="3.5" fill="none" stroke="currentColor" strokeWidth="1.8" />
        <path
          d="M6 20h12l-1.5-5h-9zM8.5 15h7"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    )
  }

  if (kind === 'battery') {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <rect x="5" y="7" width="12" height="10" rx="2" fill="none" stroke="currentColor" strokeWidth="1.8" />
        <path d="M17 10h2a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1h-2" fill="none" stroke="currentColor" strokeWidth="1.8" />
        <path d="M11 9.5l-2 3h2l-1 2.5 4-4H12l1-1.5z" fill="currentColor" />
      </svg>
    )
  }

  if (kind === 'simulation') {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <rect x="4" y="5" width="16" height="14" rx="3" fill="none" stroke="currentColor" strokeWidth="1.8" />
        <path d="M8 14l2.5-2.5 2 2 3.5-4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
        <path d="M15.5 9.5H17v1.5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    )
  }

  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeWidth="1.8" />
      <path d="m8.5 12 2.2 2.2 4.8-5.1" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

export function DashboardPage() {
  const { user } = useAuth()
  const canOpenUsers = canManageUsers(user?.role)
  const {
    data: dashboard,
    loading: dashboardLoading,
    error: dashboardError,
  } = useProtectedQuery({
    fallbackData: emptyDashboard,
    queryKey: 'dashboard',
    request: getDashboardSummary,
  })
  const { data: sites } = useProtectedQuery({
    fallbackData: [],
    queryKey: 'sites',
    request: listSites,
  })
  const { data: simulations } = useProtectedQuery({
    fallbackData: [],
    queryKey: 'simulations',
    request: listSimulations,
  })

  const siteNameById = Object.fromEntries(sites.map((site) => [site.id, site.name]))
  const recentSites = [...sites].slice(0, 3)
  const sortedSimulations = [...simulations].sort(
    (left, right) => new Date(right.created_at).getTime() - new Date(left.created_at).getTime(),
  )
  const recentSimulations = sortedSimulations.slice(0, 4)
  const feasibleCount = simulations.filter(
    (simulation) => simulation.result?.feasibility_status === 'FAISABLE',
  ).length
  const reviewCount = simulations.filter(
    (simulation) => simulation.result?.feasibility_status === 'FAISABLE_AVEC_DELESTAGE',
  ).length
  const notFeasibleCount = simulations.filter(
    (simulation) =>
      simulation.result?.feasibility_status &&
      simulation.result.feasibility_status !== 'FAISABLE' &&
      simulation.result.feasibility_status !== 'FAISABLE_AVEC_DELESTAGE',
  ).length

  const feasibilityRatio =
    dashboard.total_simulations > 0
      ? Math.round((feasibleCount / dashboard.total_simulations) * 100)
      : 0

  const feasiblePercent =
    dashboard.total_simulations > 0 ? (feasibleCount / dashboard.total_simulations) * 100 : 0
  const reviewPercent =
    dashboard.total_simulations > 0 ? (reviewCount / dashboard.total_simulations) * 100 : 0
  const notFeasiblePercent =
    dashboard.total_simulations > 0 ? (notFeasibleCount / dashboard.total_simulations) * 100 : 0

  const donutStyle = {
    background: `conic-gradient(
      #3f9167 0% ${feasiblePercent}%,
      #efb443 ${feasiblePercent}% ${feasiblePercent + reviewPercent}%,
      #cf5b4d ${feasiblePercent + reviewPercent}% ${feasiblePercent + reviewPercent + notFeasiblePercent}%,
      rgba(35, 60, 49, 0.08) ${feasiblePercent + reviewPercent + notFeasiblePercent}% 100%
    )`,
  }

  const monthlySeries = (() => {
    const now = new Date()
    const months = Array.from({ length: 6 }, (_, index) => {
      const date = new Date(now.getFullYear(), now.getMonth() - (5 - index), 1)
      return {
        key: `${date.getFullYear()}-${date.getMonth()}`,
        label: date.toLocaleDateString('fr-FR', { month: 'short', year: '2-digit' }),
        value: 0,
      }
    })

    simulations.forEach((simulation) => {
      const current = new Date(simulation.created_at)
      const key = `${current.getFullYear()}-${current.getMonth()}`
      const match = months.find((item) => item.key === key)
      if (match) {
        match.value += 1
      }
    })

    return months
  })()

  const maxSeriesValue = Math.max(...monthlySeries.map((item) => item.value), 1)
  const chartPoints = monthlySeries
    .map((item, index) => {
      const x = (index / Math.max(monthlySeries.length - 1, 1)) * 100
      const y = 100 - (item.value / maxSeriesValue) * 78
      return `${x},${y}`
    })
    .join(' ')

  const activityItems = [
    ...recentSimulations.map((simulation) => ({
      id: `simulation-${simulation.id}`,
      title: `${getSimulationTitle(simulation.id, siteNameById[simulation.site_id])} mise a jour`,
      text: simulation.result?.dimensioning_state || 'Simulation enregistree et disponible.',
      time: formatDateTime(simulation.created_at),
    })),
    ...recentSites.map((site) => ({
      id: `site-${site.id}`,
      title: `${site.name} disponible`,
      text: `${site.city}, ${site.country} · ${site.available_area_m2} m2 utiles`,
      time: `${formatCompact(site.target_backup_hours)} h backup`,
    })),
  ].slice(0, 4)

  return (
    <section className="page dashboard-page">
      <section className="dashboard-hero">
        <div className="dashboard-hero__intro">
          <span className="hero-panel__eyebrow">Vue generale</span>
          <h2>Bienvenue, {user?.full_name || 'Administrateur'}</h2>
          <p>
            Pilotez les projets solaires telecom avec une lecture plus claire des sites, des
            simulations et des verdicts de faisabilite.
          </p>
          <div className="dashboard-hero__chips">
            <span className="dashboard-chip">Dashboard optimise</span>
            <span className="dashboard-chip">Donnees recentes</span>
            <span className="dashboard-chip">Lecture decisionnelle</span>
          </div>
        </div>

        <div className="dashboard-hero__controls">
          <div className="dashboard-hero__actions">
            <Link className="button-link dashboard-primary-action" to="/simulations/new">
              + Nouvelle simulation
            </Link>
          </div>
        </div>
      </section>

      <section className="dashboard-metrics">
        <article className="dashboard-stat">
          <div className="dashboard-stat__icon">
            <DashboardIcon kind="solar" />
          </div>
          <div className="dashboard-stat__body">
            <span className="metric-card__label">PV moyen</span>
            <strong className="metric-card__value">
              {formatCompact(dashboard.average_pv_power_wc, 2)} Wc
            </strong>
            <p className="metric-card__hint">Moyenne des simulations enregistrees</p>
          </div>
        </article>

        <article className="dashboard-stat">
          <div className="dashboard-stat__icon">
            <DashboardIcon kind="battery" />
          </div>
          <div className="dashboard-stat__body">
            <span className="metric-card__label">Batterie moyenne</span>
            <strong className="metric-card__value">
              {formatCompact(dashboard.average_battery_capacity_ah, 2)} Ah
            </strong>
            <p className="metric-card__hint">Capacite nominale moyenne requise</p>
          </div>
        </article>

        <article className="dashboard-stat">
          <div className="dashboard-stat__icon">
            <DashboardIcon kind="simulation" />
          </div>
          <div className="dashboard-stat__body">
            <span className="metric-card__label">Simulations</span>
            <strong className="metric-card__value">{formatCompact(dashboard.total_simulations)}</strong>
            <p className="metric-card__hint">
              {dashboardLoading ? 'Chargement API...' : 'Calculs disponibles'}
            </p>
          </div>
        </article>

        <article className="dashboard-stat dashboard-stat--accent">
          <div className="dashboard-stat__icon">
            <DashboardIcon kind="feasibility" />
          </div>
          <div className="dashboard-stat__body">
            <span className="metric-card__label">Taux de faisabilite</span>
            <strong className="metric-card__value">{feasibilityRatio}%</strong>
            <p className="metric-card__hint">Projets faisables sur les simulations analysees</p>
          </div>
        </article>
      </section>

      {dashboardError ? (
        <p className="panel-message">API indisponible ou aucune donnee disponible pour le moment.</p>
      ) : null}

      <div className="dashboard-grid dashboard-grid--top">
        <section className="panel dashboard-panel dashboard-panel--chart">
          <div className="dashboard-panel__header">
            <div>
              <span className="section-title__eyebrow">Tendance</span>
              <h3>Evolution des simulations</h3>
            </div>
            <span className="dashboard-panel__pill">6 derniers mois</span>
          </div>

          <div className="dashboard-chart">
            <div className="dashboard-chart__graph">
              <svg viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
                <defs>
                  <linearGradient id="dashboardArea" x1="0" x2="0" y1="0" y2="1">
                    <stop offset="0%" stopColor="#3f9167" stopOpacity="0.28" />
                    <stop offset="100%" stopColor="#3f9167" stopOpacity="0.02" />
                  </linearGradient>
                </defs>
                <path
                  d={`M 0 100 L ${chartPoints.replace(/ /g, ' L ')} L 100 100 Z`}
                  fill="url(#dashboardArea)"
                />
                <polyline
                  points={chartPoints}
                  fill="none"
                  stroke="#2f7d59"
                  strokeWidth="2.6"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </div>
            <div className="dashboard-chart__labels">
              {monthlySeries.map((item) => (
                <div key={item.key} className="dashboard-chart__label">
                  <strong>{item.value}</strong>
                  <span>{item.label}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="panel dashboard-panel">
          <div className="dashboard-panel__header">
            <div>
              <span className="section-title__eyebrow">Repartition</span>
              <h3>Etat des simulations</h3>
            </div>
          </div>

          <div className="dashboard-distribution">
            <div className="dashboard-donut" style={donutStyle}>
              <div className="dashboard-donut__inner">
                <strong>{formatCompact(dashboard.total_simulations)}</strong>
                <span>Simulations</span>
              </div>
            </div>

            <div className="dashboard-legend">
              <div className="dashboard-legend__item">
                <span className="dashboard-legend__dot is-feasible" />
                <div>
                  <strong>Faisables</strong>
                  <p>{formatCompact(feasibleCount)} projet(s)</p>
                </div>
              </div>
              <div className="dashboard-legend__item">
                <span className="dashboard-legend__dot is-warning" />
                <div>
                  <strong>A revoir</strong>
                  <p>{formatCompact(reviewCount)} projet(s)</p>
                </div>
              </div>
              <div className="dashboard-legend__item">
                <span className="dashboard-legend__dot is-danger" />
                <div>
                  <strong>Non faisables</strong>
                  <p>{formatCompact(notFeasibleCount)} projet(s)</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className="panel dashboard-panel">
          <div className="dashboard-panel__header">
            <div>
              <span className="section-title__eyebrow">Actions</span>
              <h3>Raccourcis utiles</h3>
            </div>
          </div>

          <div className="dashboard-actions">
            <Link className="dashboard-action-row" to="/simulations/new">
              <span>Nouvelle simulation</span>
              <strong>→</strong>
            </Link>
            <Link className="dashboard-action-row" to="/sites">
              <span>Ajouter ou modifier un site</span>
              <strong>→</strong>
            </Link>
            <Link className="dashboard-action-row" to="/reports">
              <span>Generer un rapport</span>
              <strong>→</strong>
            </Link>
            {canOpenUsers ? (
              <Link className="dashboard-action-row" to="/users">
                <span>Gerer les utilisateurs</span>
                <strong>→</strong>
              </Link>
            ) : null}
          </div>
        </section>
      </div>

      <div className="dashboard-grid dashboard-grid--bottom">
        <section className="panel dashboard-panel">
          <div className="dashboard-panel__header">
            <div>
              <span className="section-title__eyebrow">Sites</span>
              <h3>Sites recents</h3>
            </div>
            <Link className="text-link" to="/sites">
              Voir tous
            </Link>
          </div>

          <div className="stack-list">
            {recentSites.length ? (
              recentSites.map((site) => (
                <article key={site.id} className="list-card dashboard-list-card">
                  <div className="dashboard-list-card__main">
                    <div className="dashboard-site-avatar">{site.name.slice(0, 2).toUpperCase()}</div>
                    <div>
                      <strong>{site.name}</strong>
                      <p>
                        {site.city}, {site.country} · {site.site_type}
                      </p>
                    </div>
                  </div>
                  <div className="list-card__meta">
                    <span>{formatCompact(site.available_area_m2)} m2 utiles</span>
                    <span>{formatCompact(site.target_backup_hours)} h backup</span>
                  </div>
                </article>
              ))
            ) : (
              <div className="list-card">
                <p>Aucun site enregistre.</p>
              </div>
            )}
          </div>
        </section>

        <section className="panel dashboard-panel">
          <div className="dashboard-panel__header">
            <div>
              <span className="section-title__eyebrow">Simulations</span>
              <h3>Sorties recentes</h3>
            </div>
            <Link className="text-link" to="/simulations">
              Voir toutes
            </Link>
          </div>

          <div className="stack-list">
            {recentSimulations.length ? (
              recentSimulations.map((simulation) => (
                <article key={simulation.id} className="list-card list-card--column dashboard-list-card">
                  <div className="list-card__row">
                    <div>
                      <strong>{getSimulationTitle(simulation.id, siteNameById[simulation.site_id])}</strong>
                      <p>Simulation #{simulation.id}</p>
                    </div>
                    {simulation.result?.feasibility_status ? (
                      <span
                        className={`dashboard-mini-badge ${statusToneClass[simulation.result.feasibility_status]}`}
                      >
                        {statusLabels[simulation.result.feasibility_status]}
                      </span>
                    ) : (
                      <span className="dashboard-mini-badge">En attente</span>
                    )}
                  </div>
                  <p>{simulation.result?.dimensioning_state || 'Dimensionnement disponible pour analyse.'}</p>
                  <div className="list-card__meta">
                    <span>{simulation.result?.number_of_panels ?? 0} panneaux</span>
                    <span>{simulation.result?.backup_time_hours ?? 0} h autonomie</span>
                  </div>
                </article>
              ))
            ) : (
              <div className="list-card">
                <p>Aucune simulation disponible.</p>
              </div>
            )}
          </div>
        </section>

        <section className="panel dashboard-panel">
          <div className="dashboard-panel__header">
            <div>
              <span className="section-title__eyebrow">Activite</span>
              <h3>Recente</h3>
            </div>
          </div>

          <div className="dashboard-activity">
            {activityItems.length ? (
              activityItems.map((item) => (
                <article key={item.id} className="dashboard-activity__item">
                  <span className="dashboard-activity__dot" />
                  <div>
                    <strong>{item.title}</strong>
                    <p>{item.text}</p>
                  </div>
                  <time>{item.time}</time>
                </article>
              ))
            ) : (
              <div className="list-card">
                <p>Aucune activite recente.</p>
              </div>
            )}
          </div>
        </section>
      </div>
    </section>
  )
}
