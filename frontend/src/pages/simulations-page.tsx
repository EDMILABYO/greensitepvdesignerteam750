import { StatusBadge } from '../components/status-badge'
import { SectionTitle } from '../components/section-title'
import { useProtectedQuery } from '../hooks/use-protected-query'
import { deleteSimulation, listSimulations } from '../services/simulation-service'
import { canManageSimulations } from '../lib/permissions'
import { useAuth } from '../hooks/use-auth'
import { Link } from 'react-router-dom'
import { useState } from 'react'

export function SimulationsPage() {
  const { token, user } = useAuth()
  const { data: simulations, loading, error, setData } = useProtectedQuery({
    fallbackData: [],
    queryKey: 'simulations',
    request: listSimulations,
  })
  const [message, setMessage] = useState<string | null>(null)
  const [deletingId, setDeletingId] = useState<number | null>(null)
  const canEdit = canManageSimulations(user?.role)

  async function handleDelete(simulationId: number) {
    if (!token) {
      setMessage('Connexion requise pour supprimer une simulation.')
      return
    }

    setDeletingId(simulationId)
    setMessage(null)
    try {
      await deleteSimulation(token, simulationId)
      setData(simulations.filter((simulation) => simulation.id !== simulationId))
      setMessage('Simulation supprimee avec succes.')
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Suppression impossible.')
    } finally {
      setDeletingId(null)
    }
  }

  return (
    <section className="page">
      <SectionTitle
        eyebrow="Simulations"
        title="Historique des dimensionnements"
        text="Cette page recevra ensuite les donnees FastAPI et permettra de comparer plusieurs scenarios."
      />

      {loading ? <p className="panel-message">Chargement des simulations...</p> : null}
      {error ? <p className="panel-message">API indisponible ou aucune simulation chargee.</p> : null}
      {message ? <p className="panel-message">{message}</p> : null}

      <div className="stack-list">
        {simulations.length ? simulations.map((simulation) => (
          <article key={simulation.id} className="list-card list-card--column">
            <div className="list-card__row">
              <strong>Simulation #{simulation.id}</strong>
              {simulation.result ? <StatusBadge status={simulation.result.feasibility_status} /> : null}
            </div>
            <p>{simulation.result?.dimensioning_state}</p>
            <div className="list-card__meta">
              <span>{simulation.result?.required_pv_power_wc} Wc requis</span>
              <span>{simulation.result?.number_of_panels} panneaux</span>
              <span>{simulation.result?.backup_time_hours} h</span>
            </div>
            <div className="form-actions">
              <Link className="text-link" to={`/simulations/${simulation.id}`}>
                Voir le detail
              </Link>
              {canEdit ? (
                <>
                  <Link className="text-link" to={`/simulations/${simulation.id}/edit`}>
                    Modifier
                  </Link>
                  <button
                    className="button-link button-link--ghost"
                    type="button"
                    onClick={() => handleDelete(simulation.id)}
                    disabled={deletingId === simulation.id}
                  >
                    {deletingId === simulation.id ? 'Suppression...' : 'Supprimer'}
                  </button>
                </>
              ) : null}
            </div>
          </article>
        )) : <div className="list-card"><p>Aucune simulation disponible.</p></div>}
      </div>
    </section>
  )
}
