import { Link } from 'react-router-dom'
import { SectionTitle } from '../components/section-title'
import { StatusBadge } from '../components/status-badge'
import { useProtectedQuery } from '../hooks/use-protected-query'
import { listSimulations } from '../services/simulation-service'

export function ReportsPage() {
  const { data, loading, error } = useProtectedQuery({
    fallbackData: [],
    queryKey: 'reports-simulations',
    request: listSimulations,
  })

  return (
    <section className="page">
      <SectionTitle
        eyebrow="Rapports"
        title="Sorties pretes pour le memoire et pour l'exploitation"
        text="Chaque simulation calculee peut produire un rapport technique lisible et directement exploitable."
      />

      <section className="panel">
        <p>
          L&apos;objectif est de produire un rapport clair avec les donnees d&apos;entree, les
          hypotheses, les contraintes terrain, le temps de fonctionnement et l&apos;etat final
          genere par le dimensionnement automatique.
        </p>
        {loading ? <p className="panel-message">Chargement des rapports...</p> : null}
        {error ? <p className="form-error">API indisponible ou rapports non charges.</p> : null}
      </section>

      <section className="table-panel">
        <div className="table-panel__header">
          <h3>Rapports disponibles</h3>
        </div>
        <table className="data-table">
          <thead>
            <tr>
              <th>Simulation</th>
              <th>Site</th>
              <th>Date</th>
              <th>Verdict</th>
              <th>Rapport</th>
            </tr>
          </thead>
          <tbody>
            {data.length ? (
              data.map((simulation) => (
                <tr key={simulation.id}>
                  <td>Simulation #{simulation.id}</td>
                  <td>Site #{simulation.site_id}</td>
                  <td>{new Date(simulation.created_at).toLocaleDateString('fr-FR')}</td>
                  <td>
                    {simulation.result ? (
                      <StatusBadge status={simulation.result.feasibility_status} />
                    ) : (
                      'Calcul non lance'
                    )}
                  </td>
                  <td>
                    <Link className="text-link" to={`/simulations/${simulation.id}/report`}>
                      Ouvrir le rapport
                    </Link>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={5}>Aucun rapport disponible pour le moment.</td>
              </tr>
            )}
          </tbody>
        </table>
      </section>
    </section>
  )
}
