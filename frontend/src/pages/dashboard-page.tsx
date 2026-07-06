import { MetricCard } from '../components/metric-card'
import { SectionTitle } from '../components/section-title'
import { StatusBadge } from '../components/status-badge'
import { useProtectedQuery } from '../hooks/use-protected-query'
import { getDashboardSummary, listSimulations } from '../services/simulation-service'
import { listSites } from '../services/site-service'

const emptyDashboard = {
  total_simulations: 0,
  last_simulation: null,
  average_pv_power_wc: 0,
  average_battery_capacity_ah: 0,
}

export function DashboardPage() {
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

  return (
    <section className="page">
      <div className="hero-panel">
        <div>
          <span className="hero-panel__eyebrow">Vue generale</span>
          <h2>Pilotage clair du dimensionnement solaire</h2>
          <p>
            Centralise les sites, les simulations et les sorties techniques dans une interface
            concise, lisible et exploitable pour la prise de decision.
          </p>
        </div>

        <div className="hero-panel__grid">
          <MetricCard
            label="PV moyen"
            value={`${dashboard.average_pv_power_wc.toLocaleString()} Wc`}
            hint="Moyenne des simulations enregistrees"
          />
          <MetricCard
            label="Batterie moyenne"
            value={`${dashboard.average_battery_capacity_ah.toLocaleString()} Ah`}
            hint="Capacite nominale moyenne requise"
          />
          <MetricCard
            label="Simulations"
            value={String(dashboard.total_simulations)}
            hint={dashboardLoading ? 'Chargement API...' : 'Calculs disponibles'}
          />
        </div>
      </div>

      {dashboardError ? (
        <p className="panel-message">API indisponible ou aucune donnee disponible pour le moment.</p>
      ) : null}

      <div className="page-grid">
        <section className="panel">
          <SectionTitle
            eyebrow="Sites"
            title="Contraintes terrain a surveiller"
            text="L'espace exploitable du site impacte directement la faisabilite du systeme."
          />
          <div className="stack-list">
            {sites.length ? (
              sites.map((site) => (
                <article key={site.id} className="list-card">
                  <div>
                    <strong>{site.name}</strong>
                    <p>
                      {site.city}, {site.country} · {site.site_type}
                    </p>
                  </div>
                  <div className="list-card__meta">
                    <span>{site.available_area_m2} m2 utiles</span>
                    <span>{site.target_backup_hours} h backup</span>
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

        <section className="panel">
          <SectionTitle
            eyebrow="Sorties"
            title="Verdicts de dimensionnement"
            text="Le resultat final doit fournir un etat clair, lisible et directement exploitable."
          />
          <div className="stack-list">
            {simulations.length ? (
              simulations.map((simulation) => (
                <article key={simulation.id} className="list-card list-card--column">
                  <div className="list-card__row">
                    <strong>Simulation #{simulation.id}</strong>
                    {simulation.result ? (
                      <StatusBadge status={simulation.result.feasibility_status} />
                    ) : null}
                  </div>
                  <p>{simulation.result?.dimensioning_state}</p>
                  <div className="list-card__meta">
                    <span>{simulation.result?.number_of_panels} panneaux</span>
                    <span>{simulation.result?.backup_time_hours} h autonomie</span>
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
      </div>
    </section>
  )
}
