import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { SectionTitle } from '../components/section-title'
import { StatusBadge } from '../components/status-badge'
import { useAuth } from '../hooks/use-auth'
import { useProtectedQuery } from '../hooks/use-protected-query'
import { downloadSimulationReportPdf, getSimulationReport } from '../services/simulation-service'

function formatNumber(value: number, digits = 2) {
  return new Intl.NumberFormat('fr-FR', {
    maximumFractionDigits: digits,
    minimumFractionDigits: 0,
  }).format(value)
}

function humanizeStatus(value: string) {
  return value.replaceAll('_', ' ')
}

function parseRecommendedConfiguration(value: string) {
  try {
    return JSON.parse(value) as {
      equipment_usage_plan?: {
        source: string
        installed_panel_count: number
        installed_battery_count: number
        installed_inverter_power_watts: number
        supported_equipment_count: number
        supported_units_total: number
        unsupported_equipment_count: number
        remaining_power_watts: number
        supported_equipment: Array<{
          name: string
          requested_quantity: number
          supported_quantity: number
          unit_power_watts: number
        }>
        unsupported_equipment: Array<{
          name: string
          requested_quantity: number
          supported_quantity: number
          unsupported_quantity: number
          reason: string
        }>
        analysis_rows?: Array<{
          name: string
          category: string
          requested_quantity: number
          supported_quantity: number
          unsupported_quantity: number
          unit_power_watts: number
          is_critical: boolean
          status: string
          reason: string
        }>
      }
      component_inventory_plan?: {
        missing_components_count: number
        rows: Array<{
          component: string
          required_label: string
          available_label: string
          gap_label: string
          status: string
        }>
      }
    }
  } catch {
    return {}
  }
}

export function ReportDetailPage() {
  const { simulationId } = useParams()
  const numericSimulationId = Number(simulationId)
  const { token } = useAuth()
  const [pdfBusyAction, setPdfBusyAction] = useState<'download' | 'print' | null>(null)
  const { data, loading, error } = useProtectedQuery({
    fallbackData: null,
    queryKey: `simulation-report-${numericSimulationId}`,
    request: (authToken) => getSimulationReport(authToken, numericSimulationId),
  })

  if (!data) {
    return (
      <section className="page">
        <div className="panel">
          <h3>Rapport indisponible</h3>
          <p>
            {loading
              ? 'Chargement du rapport en cours...'
              : "Le rapport n'a pas pu être chargé pour cette simulation."}
          </p>
          {error ? <p className="form-error">{error}</p> : null}
        </div>
      </section>
    )
  }

  const { site, simulation, equipment, result, assumptions, academic_notice } = data
  const criticalEquipment = equipment.filter((item) => item.is_critical)
  const nonCriticalEquipment = equipment.filter((item) => !item.is_critical)
  const generatedAt = new Date().toLocaleString('fr-FR')
  const recommendationLines = result?.recommendations
    ? result.recommendations.split('\n').filter(Boolean)
    : []
  const warningLines = result?.warnings_json ? (JSON.parse(result.warnings_json) as string[]) : []
  const equipmentPlan = result
    ? parseRecommendedConfiguration(result.recommended_configuration_json).equipment_usage_plan
    : undefined
  const componentInventoryPlan = result
    ? parseRecommendedConfiguration(result.recommended_configuration_json).component_inventory_plan
    : undefined

  async function handleDownloadPdf() {
    if (!token) return
    setPdfBusyAction('download')
    try {
      const blob = await downloadSimulationReportPdf(token, simulation.id)
      const url = URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `hayat-solar-sizer-rapport-simulation-${simulation.id}.pdf`
      document.body.appendChild(link)
      link.click()
      link.remove()
      URL.revokeObjectURL(url)
    } finally {
      setPdfBusyAction(null)
    }
  }

  async function handlePrintPdf() {
    if (!token) return
    setPdfBusyAction('print')

    try {
      const blob = await downloadSimulationReportPdf(token, simulation.id)
      const url = URL.createObjectURL(blob)
      const iframe = document.createElement('iframe')
      iframe.style.position = 'fixed'
      iframe.style.width = '0'
      iframe.style.height = '0'
      iframe.style.border = '0'
      iframe.style.right = '0'
      iframe.style.bottom = '0'
      iframe.src = url

      let cleaned = false
      const cleanup = () => {
        if (cleaned) return
        cleaned = true
        iframe.remove()
        URL.revokeObjectURL(url)
        window.removeEventListener('afterprint', cleanup)
      }

      iframe.onload = () => {
        const printWindow = iframe.contentWindow
        if (!printWindow) {
          cleanup()
          return
        }

        window.addEventListener('afterprint', cleanup)
        printWindow.focus()
        printWindow.print()
        window.setTimeout(cleanup, 60000)
      }

      document.body.appendChild(iframe)
    } finally {
      setPdfBusyAction(null)
    }
  }

  return (
    <section className="page report-document">
      <SectionTitle
        eyebrow="Rapport technique"
        title={`Rapport de dimensionnement - Simulation #${simulation.id}`}
        text="Ce rapport synthétise les contraintes du site, les hypothèses de calcul, l’état de sortie final et les protections requises pour un secours photovoltaïque professionnel."
      />

      <div className="form-actions">
        <button
          className="button-link button-link--solid"
          type="button"
          onClick={handleDownloadPdf}
          disabled={pdfBusyAction !== null}
        >
          Télécharger PDF
        </button>
        <button
          className="button-link button-link--ghost"
          type="button"
          onClick={handlePrintPdf}
          disabled={pdfBusyAction !== null}
        >
          {pdfBusyAction === 'print' ? 'Preparation de l impression...' : 'Imprimer'}
        </button>
        <Link className="button-link button-link--ghost" to={`/simulations/${simulation.id}`}>
          Retour à la simulation
        </Link>
        <Link className="button-link button-link--ghost" to="/reports">
          Retour aux rapports
        </Link>
      </div>

      <section className="panel report-cover">
        <div className="report-cover__header">
          <div>
            <span className="section-title__eyebrow">HAYAT-Solar Sizer</span>
            <h3>Rapport de dimensionnement photovoltaïque de back-up</h3>
            <p className="report-cover__lead">
              Sortie technique consolidée pour arbitrer la faisabilité, la continuité BTS, les
              protections électriques et la conformité de la mise à la terre.
            </p>
          </div>
          {result ? <StatusBadge status={result.feasibility_status} /> : null}
        </div>
        <div className="report-cover__meta">
          <span>Site: {site.name}</span>
          <span>Simulation: #{simulation.id}</span>
          <span>Généré le: {generatedAt}</span>
        </div>
      </section>

      {result ? (
        <section className="hero-panel hero-panel--result">
          <div>
            <span className="hero-panel__eyebrow">Synthèse exécutive</span>
            <h2>Verdict professionnel de dimensionnement</h2>
            <p>
              Le rapport ci-dessous rassemble les données essentielles à la décision: faisabilité,
              dimensionnement des composants, contraintes d’implantation, protection des
              équipements et conditions de sécurité.
            </p>
          </div>
          <div className="hero-panel__grid">
            <div className="metric-card">
              <span className="metric-card__label">Verdict</span>
              <strong className="metric-card__value">{humanizeStatus(result.feasibility_status)}</strong>
              <span className="metric-card__hint">{result.dimensioning_state}</span>
            </div>
            <div className="metric-card">
              <span className="metric-card__label">Autonomie obtenue</span>
              <strong className="metric-card__value">{formatNumber(result.backup_time_hours)} h</strong>
              <span className="metric-card__hint">Sur charges critiques</span>
            </div>
            <div className="metric-card">
              <span className="metric-card__label">Coût total</span>
              <strong className="metric-card__value">{formatNumber(result.total_cost)} USD</strong>
              <span className="metric-card__hint">Investissement estimatif</span>
            </div>
          </div>
        </section>
      ) : null}

      <section className="panel report-panel">
        <div className="list-card__row">
          <div>
            <h3>Identification du site</h3>
            <p>
              {site.name} - {site.city}, {site.country}
            </p>
          </div>
          {result ? <StatusBadge status={result.feasibility_status} /> : null}
        </div>

        <div className="report-grid">
          <div className="list-card">
            <strong>Type de site</strong>
            <p>{site.site_type}</p>
          </div>
          <div className="list-card">
            <strong>Surface exploitable</strong>
            <p>
              {formatNumber(site.available_area_m2)} m² - ratio utile{' '}
              {formatNumber((site.usable_area_ratio ?? 1) * 100, 0)}%
            </p>
          </div>
          <div className="list-card">
            <strong>Autonomie cible</strong>
            <p>{formatNumber(site.target_backup_hours)} h</p>
          </div>
          <div className="list-card">
            <strong>Scénario groupe</strong>
            <p>
              {site.generator_failure_scenario
                ? 'Défaillance du groupe prise en compte'
                : 'Groupe disponible comme secours complémentaire'}
            </p>
          </div>
        </div>
      </section>

      <div className="page-grid">
        <section className="panel">
          <h3>Hypothèses de calcul</h3>
          <ul className="feature-list feature-list--tight">
            {assumptions.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
          <p className="panel-message">{academic_notice}</p>
        </section>

        <section className="panel">
          <h3>Paramètres de simulation</h3>
          <div className="stack-list">
            <div className="list-card">
              <strong>Panneau solaire</strong>
              <p>
                {simulation.panel_type} - {formatNumber(simulation.panel_power_watts)} Wc -{' '}
                {formatNumber(simulation.panel_area_m2)} m²
              </p>
            </div>
            <div className="list-card">
              <strong>Batterie</strong>
              <p>
                {simulation.battery_type} - {formatNumber(simulation.battery_capacity_ah)} Ah -{' '}
                {formatNumber(simulation.battery_voltage)} V
              </p>
            </div>
            <div className="list-card">
              <strong>Rendements et pertes</strong>
              <p>
                Régulateur {formatNumber(simulation.controller_efficiency * 100, 0)}% - Onduleur{' '}
                {formatNumber(simulation.inverter_efficiency * 100, 0)}% - Câbles{' '}
                {formatNumber(simulation.cable_loss_factor * 100, 0)}%
              </p>
            </div>
            <div className="list-card">
              <strong>Protection et câbles</strong>
              <p>
                DC {formatNumber(simulation.dc_cable_length_m, 0)} m /{' '}
                {formatNumber(simulation.dc_voltage_drop_limit_percent, 0)}% - AC{' '}
                {formatNumber(simulation.ac_cable_length_m, 0)} m /{' '}
                {formatNumber(simulation.ac_voltage_drop_limit_percent, 0)}%
              </p>
            </div>
          </div>
        </section>
      </div>

      <section className="table-panel">
        <div className="table-panel__header">
          <h3>Audit énergétique des équipements</h3>
        </div>
        <table className="data-table">
          <thead>
            <tr>
              <th>Équipement</th>
              <th>Catégorie</th>
              <th>Qté</th>
              <th>Puissance</th>
              <th>Heures/j</th>
              <th>Criticité</th>
            </tr>
          </thead>
          <tbody>
            {equipment.map((item) => (
              <tr key={item.id}>
                <td>{item.name}</td>
                <td>{item.category}</td>
                <td>{item.quantity}</td>
                <td>{formatNumber(item.power_watts)} W</td>
                <td>{formatNumber(item.hours_per_day)} h</td>
                <td>{item.is_critical ? 'Critique' : 'Non critique'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <div className="page-grid">
        <section className="panel">
          <h3>Répartition des charges</h3>
          <div className="stack-list">
            <div className="list-card">
              <strong>Charges critiques</strong>
              <p>{criticalEquipment.length} équipement(s)</p>
            </div>
            <div className="list-card">
              <strong>Charges non critiques</strong>
              <p>{nonCriticalEquipment.length} équipement(s)</p>
            </div>
          </div>
        </section>

        <section className="panel">
          <h3>Conclusion rapide</h3>
          <p>
            {result
              ? result.dimensioning_state
              : "La simulation existe, mais le calcul n'a pas encore été lancé."}
          </p>
        </section>
      </div>

      {result ? (
        <>
          <section className="table-panel">
            <div className="table-panel__header">
              <h3>Résultats de dimensionnement</h3>
            </div>
            <table className="data-table">
              <tbody>
                <tr>
                  <th>Puissance totale</th>
                  <td>{formatNumber(result.total_power_watts)} W</td>
                </tr>
                <tr>
                  <th>Énergie journalière</th>
                  <td>{formatNumber(result.daily_energy_wh)} Wh/j</td>
                </tr>
                <tr>
                  <th>Puissance PV requise</th>
                  <td>{formatNumber(result.required_pv_power_wc)} Wc</td>
                </tr>
                <tr>
                  <th>Nombre de panneaux</th>
                  <td>{result.number_of_panels}</td>
                </tr>
                <tr>
                  <th>Surface avec espacement</th>
                  <td>{formatNumber(result.panel_surface_with_spacing_m2)} m²</td>
                </tr>
                <tr>
                  <th>Surface disponible</th>
                  <td>{formatNumber(result.available_surface_m2)} m²</td>
                </tr>
                <tr>
                  <th>Capacité batterie requise</th>
                  <td>{formatNumber(result.required_battery_capacity_ah)} Ah</td>
                </tr>
                <tr>
                  <th>Nombre de batteries</th>
                  <td>{result.number_of_batteries}</td>
                </tr>
                <tr>
                  <th>Autonomie obtenue</th>
                  <td>{formatNumber(result.backup_time_hours)} h</td>
                </tr>
                <tr>
                  <th>Onduleur recommandé</th>
                  <td>{formatNumber(result.inverter_power_watts)} W</td>
                </tr>
                <tr>
                  <th>Coût total estimatif</th>
                  <td>{formatNumber(result.total_cost)} USD</td>
                </tr>
              </tbody>
            </table>
          </section>

          <div className="page-grid">
            <section className="panel">
              <h3>État final généré</h3>
              <p>{result.dimensioning_state}</p>
              <div className="stack-list" style={{ marginTop: '1rem' }}>
                <div className="list-card">
                  <strong>Surface</strong>
                  <p>{humanizeStatus(result.surface_status)}</p>
                </div>
                <div className="list-card">
                  <strong>Délestage</strong>
                  <p>{result.load_shedding_message}</p>
                </div>
              </div>
            </section>

            <section className="panel">
              <h3>Recommandations</h3>
              <ul className="feature-list feature-list--tight">
                {recommendationLines.map((line) => (
                  <li key={line}>{line}</li>
                ))}
              </ul>
            </section>
          </div>

          {warningLines.length ? (
            <section className="panel">
              <h3>Points de vigilance</h3>
              <ul className="feature-list feature-list--tight">
                {warningLines.map((warning) => (
                  <li key={warning}>{warning}</li>
                ))}
              </ul>
            </section>
          ) : null}

          {equipmentPlan ? (
            <section className="table-panel">
              <div className="table-panel__header">
                <h3>Plan d'usage recommande des equipements</h3>
              </div>
              <table className="data-table">
                <tbody>
                  <tr>
                    <th>Base de calcul</th>
                    <td>
                      {equipmentPlan.source === 'entered_quantities'
                        ? `Materiel saisi: ${equipmentPlan.installed_panel_count} panneau(x), ${equipmentPlan.installed_battery_count} batterie(s), onduleur ${formatNumber(equipmentPlan.installed_inverter_power_watts)} W`
                        : 'Dimensionnement recommande automatiquement'}
                    </td>
                  </tr>
                  <tr>
                    <th>Equipements alimentables</th>
                    <td>{equipmentPlan.supported_equipment_count}</td>
                  </tr>
                  <tr>
                    <th>Unites alimentables</th>
                    <td>{equipmentPlan.supported_units_total}</td>
                  </tr>
                  <tr>
                    <th>Equipements a limiter</th>
                    <td>{equipmentPlan.unsupported_equipment_count}</td>
                  </tr>
                  <tr>
                    <th>Marge puissance restante</th>
                    <td>{formatNumber(equipmentPlan.remaining_power_watts)} W</td>
                  </tr>
                </tbody>
              </table>
            </section>
          ) : null}

          {equipmentPlan?.supported_equipment.length ? (
            <section className="table-panel">
              <div className="table-panel__header">
                <h3>
                  {equipmentPlan.source === 'entered_quantities'
                    ? 'Equipements pouvant fonctionner avec le materiel saisi'
                    : 'Equipements pouvant etre utilises'}
                </h3>
              </div>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Equipement</th>
                    <th>Quantite recommandee</th>
                    <th>Quantite demandee</th>
                    <th>Puissance unitaire</th>
                  </tr>
                </thead>
                <tbody>
                  {equipmentPlan.supported_equipment.map((item) => (
                    <tr key={item.name}>
                      <td>{item.name}</td>
                      <td>{item.supported_quantity}</td>
                      <td>{item.requested_quantity}</td>
                      <td>{formatNumber(item.unit_power_watts)} W</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          ) : null}

          {equipmentPlan?.unsupported_equipment.length ? (
            <section className="table-panel">
              <div className="table-panel__header">
                <h3>Equipements a delester ou reduire</h3>
              </div>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Equipement</th>
                    <th>Supporte</th>
                    <th>Demande</th>
                    <th>A retirer</th>
                    <th>Motif</th>
                  </tr>
                </thead>
                <tbody>
                  {equipmentPlan.unsupported_equipment.map((item) => (
                    <tr key={`${item.name}-${item.reason}`}>
                      <td>{item.name}</td>
                      <td>{item.supported_quantity}</td>
                      <td>{item.requested_quantity}</td>
                      <td>{item.unsupported_quantity}</td>
                      <td>{item.reason}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          ) : null}

          {componentInventoryPlan ? (
            <section className="table-panel">
              <div className="table-panel__header">
                <h3>Comparaison materiel disponible / besoin systeme</h3>
              </div>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Composant</th>
                    <th>Requis</th>
                    <th>Disponible</th>
                    <th>Ecart</th>
                    <th>Statut</th>
                  </tr>
                </thead>
                <tbody>
                  {componentInventoryPlan.rows.map((row) => (
                    <tr key={row.component}>
                      <td>{row.component}</td>
                      <td>{row.required_label}</td>
                      <td>{row.available_label}</td>
                      <td>{row.gap_label}</td>
                      <td>{humanizeStatus(row.status)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          ) : null}

          <section className="table-panel">
            <div className="table-panel__header">
              <h3>Protection, câbles et mise à la terre</h3>
            </div>
            <table className="data-table">
              <tbody>
                <tr>
                  <th>Section câble DC</th>
                  <td>{formatNumber(result.dc_cable_section_mm2)} mm²</td>
                </tr>
                <tr>
                  <th>Section câble AC</th>
                  <td>{formatNumber(result.ac_cable_section_mm2)} mm²</td>
                </tr>
                <tr>
                  <th>Conducteur de terre</th>
                  <td>{formatNumber(result.earth_cable_section_mm2)} mm²</td>
                </tr>
                <tr>
                  <th>Protection DC</th>
                  <td>{formatNumber(result.dc_breaker_rating_a)} A</td>
                </tr>
                <tr>
                  <th>Protection AC</th>
                  <td>{formatNumber(result.ac_breaker_rating_a)} A</td>
                </tr>
                <tr>
                  <th>Parafoudre</th>
                  <td>
                    DC {result.dc_spd_required ? 'Oui' : 'Non'} - AC{' '}
                    {result.ac_spd_required ? 'Oui' : 'Non'}
                  </td>
                </tr>
                <tr>
                  <th>Protection foudre</th>
                  <td>{result.lightning_protection_required ? 'Oui' : 'Non'}</td>
                </tr>
                <tr>
                  <th>Résistance de terre cible</th>
                  <td>{formatNumber(result.recommended_earthing_resistance_ohm)} ohm</td>
                </tr>
                <tr>
                  <th>Résistance de terre mesurée</th>
                  <td>{formatNumber(result.measured_earthing_resistance_ohm)} ohm</td>
                </tr>
                <tr>
                  <th>Statut de terre</th>
                  <td>{humanizeStatus(result.grounding_status)}</td>
                </tr>
              </tbody>
            </table>
          </section>
        </>
      ) : null}

      <section className="panel">
        <h3>Validation</h3>
        <div className="report-signatures">
          <div className="list-card">
            <strong>Élaboré par</strong>
            <p>Nom: ________________________________</p>
            <p>Date: ________________________________</p>
            <p>Signature: ___________________________</p>
          </div>
          <div className="list-card">
            <strong>Validé par</strong>
            <p>Nom: ________________________________</p>
            <p>Date: ________________________________</p>
            <p>Signature: ___________________________</p>
          </div>
        </div>
      </section>
    </section>
  )
}
