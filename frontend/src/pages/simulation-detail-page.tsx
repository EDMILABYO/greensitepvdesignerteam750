import { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { MetricCard } from '../components/metric-card'
import { SectionTitle } from '../components/section-title'
import { StatusBadge } from '../components/status-badge'
import { useProtectedQuery } from '../hooks/use-protected-query'
import { useAuth } from '../hooks/use-auth'
import { listEquipment } from '../services/equipment-service'
import {
  calculateSimulation,
  deleteSimulation,
  getSimulation,
  updateSimulation,
} from '../services/simulation-service'
import type { EquipmentItem, SimulationDetail } from '../types/domain'

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

function safeTimestamp(value?: string | null) {
  if (!value) return null
  const time = new Date(value).getTime()
  return Number.isFinite(time) ? time : null
}

function looksLikeSystemHardware(item: EquipmentItem) {
  const value = `${item.name} ${item.category}`.toLocaleLowerCase('fr')
  return /panneau|batterie|onduleur|r[ée]gulateur|parafoudre|mise [àa] la terre/.test(value)
}

export function SimulationDetailPage() {
  const { simulationId } = useParams()
  const numericSimulationId = Number(simulationId)
  const { token } = useAuth()
  const { data, loading, error, setData } = useProtectedQuery({
    fallbackData: null,
    queryKey: `simulation-detail-${numericSimulationId}`,
    request: (authToken) => getSimulation(authToken, numericSimulationId),
  })
  const { data: siteEquipment } = useProtectedQuery({
    fallbackData: [] as EquipmentItem[],
    queryKey: data ? `simulation-site-equipment-${data.site_id}` : `simulation-site-equipment-none`,
    request: (authToken) =>
      data ? listEquipment(authToken, data.site_id) : Promise.resolve([] as EquipmentItem[]),
  })
  const [message, setMessage] = useState<string | null>(null)
  const [calculating, setCalculating] = useState(false)
  const [savingHardware, setSavingHardware] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [autoRefreshing, setAutoRefreshing] = useState(false)

  async function handleCalculate() {
    if (!token || !data) {
      setMessage('Connexion requise pour lancer le calcul.')
      return
    }

    setCalculating(true)
    setMessage(null)
    try {
      const result = await calculateSimulation(token, numericSimulationId)
      setData({ ...(data as SimulationDetail), result })
      setMessage('Calcul effectue avec succes.')
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Calcul impossible.')
    } finally {
      setCalculating(false)
    }
  }

  async function handleDeleteSimulation() {
    if (!token || !data) {
      setMessage('Connexion requise pour supprimer la simulation.')
      return
    }

    setDeleting(true)
    setMessage(null)
    try {
      await deleteSimulation(token, numericSimulationId)
      window.location.href = '/simulations'
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Suppression impossible.')
    } finally {
      setDeleting(false)
    }
  }
  const latestEquipmentUpdate = useMemo(() => {
    if (!siteEquipment.length) return null
    return siteEquipment.reduce((latest, item) => {
      const date = safeTimestamp(item.updated_at) ?? 0
      return date > latest ? date : latest
    }, 0)
  }, [siteEquipment])

  useEffect(() => {
    async function refreshIfStale() {
      if (!token || !data?.result || !latestEquipmentUpdate || autoRefreshing) return
      const resultCreatedAt = safeTimestamp(data.result.created_at)
      if (!resultCreatedAt) return
      if (latestEquipmentUpdate <= resultCreatedAt) return

      setAutoRefreshing(true)
      try {
        const refreshed = await calculateSimulation(token, numericSimulationId)
        setData({ ...(data as SimulationDetail), result: refreshed })
        setMessage("Analyse mise a jour automatiquement apres modification des equipements.")
      } catch {
        // keep current result if auto-refresh fails
      } finally {
        setAutoRefreshing(false)
      }
    }

    void refreshIfStale()
  }, [token, data, latestEquipmentUpdate, autoRefreshing, numericSimulationId, setData])

  if (!data) {
    return (
      <section className="page">
        <div className="panel">
          <h2>Simulation introuvable</h2>
          <p>Aucune simulation correspondante n'a ete trouvee.</p>
        </div>
      </section>
    )
  }

  const result = data.result
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
  const equipmentAnalysisRows =
    equipmentPlan?.analysis_rows && equipmentPlan.analysis_rows.length > 0
      ? equipmentPlan.analysis_rows
      : [
          ...equipmentPlan?.supported_equipment.map((item) => ({
            ...item,
            category: '',
            unsupported_quantity: 0,
            status: 'ALIMENTABLE',
            reason: 'OK',
          })) ?? [],
          ...equipmentPlan?.unsupported_equipment.map((item) => ({
            ...item,
            category: '',
            unit_power_watts: 0,
            is_critical: false,
            status: item.supported_quantity > 0 ? 'PARTIEL' : 'NON_ALIMENTABLE',
          })) ?? [],
        ]
  const automaticRequirementRows = componentInventoryPlan?.rows ?? []
  const hasRecordedLoads = siteEquipment.length > 0
  const shouldShowAutomaticRequirements =
    !hasRecordedLoads && equipmentAnalysisRows.length === 0 && automaticRequirementRows.length > 0
  const possibleMisclassifiedHardware = siteEquipment.filter(looksLikeSystemHardware)

  async function handleSaveHardware(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!token || !data) {
      setMessage('Connexion requise pour enregistrer le materiel disponible.')
      return
    }

    const formData = new FormData(event.currentTarget)
    const nextData = {
      ...data,
      installed_panel_count: Number(formData.get('installed_panel_count') ?? 0),
      installed_battery_count: Number(formData.get('installed_battery_count') ?? 0),
      installed_inverter_power_watts: Number(formData.get('installed_inverter_power_watts') ?? 0),
      installed_controller_count: Number(formData.get('installed_controller_count') ?? 0),
      installed_controller_current_a: Number(formData.get('installed_controller_current_a') ?? 0),
      installed_dc_spd_count: Number(formData.get('installed_dc_spd_count') ?? 0),
      installed_ac_spd_count: Number(formData.get('installed_ac_spd_count') ?? 0),
      installed_earthing_kit_count: Number(formData.get('installed_earthing_kit_count') ?? 0),
    }

    setSavingHardware(true)
    setMessage(null)
    try {
      const updated = await updateSimulation(token, numericSimulationId, {
        site_id: nextData.site_id,
        critical_active_power_w: nextData.critical_active_power_w,
        backup_time_hours: nextData.backup_time_hours,
        power_factor: nextData.power_factor,
        air_conditioner_power_w: nextData.air_conditioner_power_w,
        air_conditioner_is_critical: nextData.air_conditioner_is_critical,
        other_critical_power_w: nextData.other_critical_power_w,
        other_non_critical_power_w: nextData.other_non_critical_power_w,
        panel_power_watts: nextData.panel_power_watts,
        panel_type: nextData.panel_type,
        panel_length_m: nextData.panel_length_m,
        panel_width_m: nextData.panel_width_m,
        panel_area_m2: nextData.panel_area_m2,
        panel_spacing_factor: nextData.panel_spacing_factor,
        installed_panel_count: nextData.installed_panel_count,
        battery_capacity_ah: nextData.battery_capacity_ah,
        battery_voltage: nextData.battery_voltage,
        battery_type: nextData.battery_type,
        battery_energy_kwh: nextData.battery_energy_kwh,
        installed_battery_count: nextData.installed_battery_count,
        installed_inverter_power_watts: nextData.installed_inverter_power_watts,
        installed_controller_count: nextData.installed_controller_count,
        installed_controller_current_a: nextData.installed_controller_current_a,
        installed_dc_spd_count: nextData.installed_dc_spd_count,
        installed_ac_spd_count: nextData.installed_ac_spd_count,
        installed_earthing_kit_count: nextData.installed_earthing_kit_count,
        battery_dod: nextData.battery_dod,
        battery_efficiency: nextData.battery_efficiency,
        controller_efficiency: nextData.controller_efficiency,
        inverter_efficiency: nextData.inverter_efficiency,
        cable_loss_factor: nextData.cable_loss_factor,
        dc_cable_length_m: nextData.dc_cable_length_m,
        ac_cable_length_m: nextData.ac_cable_length_m,
        dc_voltage_drop_limit_percent: nextData.dc_voltage_drop_limit_percent,
        ac_voltage_drop_limit_percent: nextData.ac_voltage_drop_limit_percent,
        temperature_loss_factor: nextData.temperature_loss_factor,
        dust_loss_factor: nextData.dust_loss_factor,
        safety_factor: nextData.safety_factor,
        lightning_protection_required: nextData.lightning_protection_required,
        dc_spd_required: nextData.dc_spd_required,
        ac_spd_required: nextData.ac_spd_required,
        earthing_required: nextData.earthing_required,
        earthing_resistance_target_ohm: nextData.earthing_resistance_target_ohm,
        earthing_resistance_measured_ohm: nextData.earthing_resistance_measured_ohm,
        panel_unit_price: nextData.panel_unit_price,
        battery_unit_price: nextData.battery_unit_price,
        inverter_price: nextData.inverter_price,
        controller_price: nextData.controller_price,
        air_conditioner_price: nextData.air_conditioner_price,
        accessories_price: nextData.accessories_price,
        protection_price: nextData.protection_price,
        installation_price: nextData.installation_price,
        labor_price: nextData.labor_price,
        maintenance_price: nextData.maintenance_price,
        snel_operating_cost: nextData.snel_operating_cost,
        generator_operating_cost: nextData.generator_operating_cost,
      })
      const recalculatedResult = await calculateSimulation(token, numericSimulationId)
      setData({ ...updated, result: recalculatedResult })
      setMessage("Materiel disponible mis a jour et analyse rafraichie.")
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Mise a jour impossible.')
    } finally {
      setSavingHardware(false)
    }
  }

  return (
    <section className="page">
      <SectionTitle
        eyebrow="Resultat du calcul"
        title={`Simulation #${data.id}`}
        text="Lis d'abord le verdict et les chiffres essentiels. Les details techniques sont disponibles plus bas seulement si tu en as besoin."
      />

      <div className="form-actions">
        <button
          className="button-link button-link--solid"
          type="button"
          onClick={handleCalculate}
          disabled={calculating}
        >
          {calculating ? 'Calcul en cours...' : 'Lancer le calcul'}
        </button>
        <Link className="button-link button-link--ghost" to="/simulations">
          Retour aux simulations
        </Link>
        <Link className="button-link button-link--ghost" to={`/sites/${data.site_id}`}>
          Gerer les equipements du site
        </Link>
        <Link className="button-link button-link--ghost" to={`/simulations/${data.id}/edit`}>
          Modifier la simulation
        </Link>
        <Link className="button-link button-link--ghost" to={`/simulations/${data.id}/report`}>
          Ouvrir le rapport
        </Link>
        <button
          className="button-link button-link--ghost"
          type="button"
          onClick={handleDeleteSimulation}
          disabled={deleting}
        >
          {deleting ? 'Suppression...' : 'Supprimer la simulation'}
        </button>
        {message ? <p className="form-message">{message}</p> : null}
        {loading ? <p className="form-message">Chargement du detail simulation...</p> : null}
        {error ? <p className="form-error">API indisponible ou simulation non chargee.</p> : null}
      </div>

      <section className="panel anchor-section" id="inventaire-materiel">
        <div className="inventory-header">
          <div>
            <h3>Materiel disponible</h3>
            <p className="panel-message">Quantites deja presentes sur le site.</p>
          </div>
          <span className="inventory-header__tag">Inventaire</span>
        </div>
        <form className="form-grid inventory-form" onSubmit={handleSaveHardware}>
          <label>
            <span>Panneaux disponibles</span>
            <input
              name="installed_panel_count"
              type="number"
              min="0"
              defaultValue={data.installed_panel_count}
            />
          </label>
          <label>
            <span>Batteries disponibles</span>
            <input
              name="installed_battery_count"
              type="number"
              min="0"
              defaultValue={data.installed_battery_count}
            />
          </label>
          <label>
            <span>Onduleur disponible (W)</span>
            <input
              name="installed_inverter_power_watts"
              type="number"
              min="0"
              defaultValue={data.installed_inverter_power_watts}
            />
          </label>
          <details className="simple-details inventory-details form-grid__full">
            <summary>Regulateurs et protections</summary>
            <div className="simple-details__content">
              <div className="form-grid">
                <label>
                  <span>Regulateurs disponibles</span>
                  <input
                    name="installed_controller_count"
                    type="number"
                    min="0"
                    defaultValue={data.installed_controller_count}
                  />
                </label>
                <label>
                  <span>Courant par regulateur (A)</span>
                  <input
                    name="installed_controller_current_a"
                    type="number"
                    min="0"
                    defaultValue={data.installed_controller_current_a}
                  />
                </label>
                <label>
                  <span>Parafoudres DC</span>
                  <input
                    name="installed_dc_spd_count"
                    type="number"
                    min="0"
                    defaultValue={data.installed_dc_spd_count}
                  />
                </label>
                <label>
                  <span>Parafoudres AC</span>
                  <input
                    name="installed_ac_spd_count"
                    type="number"
                    min="0"
                    defaultValue={data.installed_ac_spd_count}
                  />
                </label>
                <label>
                  <span>Kits de mise a la terre</span>
                  <input
                    name="installed_earthing_kit_count"
                    type="number"
                    min="0"
                    defaultValue={data.installed_earthing_kit_count}
                  />
                </label>
              </div>
            </div>
          </details>
          <div className="form-actions form-grid__full">
            <button className="button-link button-link--solid" type="submit" disabled={savingHardware}>
              {savingHardware ? 'Enregistrement...' : 'Enregistrer'}
            </button>
          </div>
        </form>
      </section>

      {result ? (
        <>
          <section className="hero-panel hero-panel--result hero-panel--simple">
            <div>
              <span className="hero-panel__eyebrow">Verdict de dimensionnement</span>
              <h2>Le systeme est-il faisable ?</h2>
              <p>{result.dimensioning_state}</p>
            </div>
            <div className="hero-panel__grid hero-panel__grid--simple">
              <MetricCard
                label="Verdict"
                value={humanizeStatus(result.feasibility_status)}
                hint="Decision automatique"
              />
              <MetricCard
                label="Autonomie"
                value={`${formatNumber(result.backup_time_hours)} h`}
                hint="Autonomie obtenue"
              />
              <MetricCard
                label="Cout"
                value={`${formatNumber(result.total_cost)} USD`}
                hint="Estimation globale"
              />
            </div>
          </section>

          <div className="page-grid page-grid--metrics">
            <MetricCard
              label="PV requis"
              value={`${formatNumber(result.required_pv_power_wc)} Wc`}
              hint={`${result.number_of_panels} panneaux`}
            />
            <MetricCard
              label="Batteries"
              value={`${result.number_of_batteries}`}
              hint={`${formatNumber(result.required_battery_capacity_ah)} Ah requis`}
            />
            <MetricCard
              label="Surface requise"
              value={`${formatNumber(result.panel_surface_with_spacing_m2)} m2`}
              hint={`Disponible: ${formatNumber(result.available_surface_m2)} m2`}
            />
            <MetricCard
              label="Onduleur"
              value={`${formatNumber(result.inverter_power_watts)} W`}
              hint="Puissance recommandee"
            />
          </div>

          <div className="page-grid">
            <section className="panel">
              <div className="list-card__row">
                <h3>Resume rapide</h3>
                <StatusBadge status={result.feasibility_status} />
              </div>
              <div className="stack-list" style={{ marginTop: '1rem' }}>
                <div className="list-card">
                  <strong>Charges critiques</strong>
                  <p>{formatNumber(result.critical_power_watts)} W · {formatNumber(result.critical_energy_wh)} Wh</p>
                </div>
                <div className="list-card">
                  <strong>Surface</strong>
                  <p>{formatNumber(result.available_surface_m2)} m2 disponible pour {formatNumber(result.panel_surface_with_spacing_m2)} m2 requis.</p>
                </div>
                <div className="list-card">
                  <strong>Delestage</strong>
                  <p>{result.load_shedding_message}</p>
                </div>
              </div>
            </section>

            <section className="panel">
              <h3>Ce qu'il faut faire</h3>
              <div className="stack-list">
                {warningLines.length ? (
                  <div className="list-card list-card--warning">
                    <strong>Points a verifier</strong>
                    <ul className="feature-list feature-list--tight">
                      {warningLines.slice(0, 4).map((warning) => (
                        <li key={warning}>{warning}</li>
                      ))}
                    </ul>
                  </div>
                ) : null}

                <div className="list-card list-card--accent">
                  <strong>Actions recommandees</strong>
                  <ul className="feature-list feature-list--tight">
                    {recommendationLines.slice(0, 5).map((line) => (
                      <li key={line}>{line}</li>
                    ))}
                  </ul>
                </div>
              </div>
            </section>
          </div>

          {equipmentPlan ? (
            <div className="page-grid">
              <section className="panel">
                <h3>Resume de l'analyse du stock de secours</h3>
                <div className="stack-list">
                  <div className="list-card">
                    <strong>Base de calcul</strong>
                    <p>
                      {equipmentPlan.source === 'entered_quantities'
                        ? `Stock saisi: ${equipmentPlan.installed_panel_count} panneau(x), ${equipmentPlan.installed_battery_count} batterie(s), onduleur ${formatNumber(equipmentPlan.installed_inverter_power_watts)} W`
                        : 'Dimensionnement recommande automatiquement'}
                    </p>
                  </div>
                  <div className="list-card">
                    <strong>Charges completement alimentables</strong>
                    <p>{equipmentPlan.supported_equipment_count} type(s) · {equipmentPlan.supported_units_total} unite(s)</p>
                  </div>
                  <div className="list-card">
                    <strong>Charges a limiter ou delester</strong>
                    <p>{equipmentPlan.unsupported_equipment_count} type(s)</p>
                  </div>
                  <div className="list-card">
                    <strong>Marge de puissance restante</strong>
                    <p>{formatNumber(equipmentPlan.remaining_power_watts)} W</p>
                  </div>
                </div>
              </section>

              <section className="table-panel">
                <div className="table-panel__header">
                  <div>
                    <h3>
                      {shouldShowAutomaticRequirements
                        ? 'Resultat automatique des equipements calcules'
                        : equipmentPlan.source === 'entered_quantities'
                          ? 'Resultat: charges du site pouvant fonctionner avec le stock saisi'
                          : 'Resultat: analyse des charges du site'}
                    </h3>
                    <p className="panel-message">
                      {shouldShowAutomaticRequirements
                        ? "Aucune charge detaillee n'est encore enregistree sur le site. Le systeme affiche donc automatiquement les equipements calcules et l'ecart avec l'inventaire saisi."
                        : "Ce tableau analyse les charges du site enregistrees plus bas et indique combien d'unites peuvent reellement fonctionner avec le materiel de secours que tu as saisi ci-dessus."}
                    </p>
                  </div>
                  <Link className="button-link button-link--ghost" to={`/sites/${data.site_id}`}>
                    {shouldShowAutomaticRequirements
                      ? 'Ajouter les charges du site'
                      : 'Gerer les charges du site'}
                  </Link>
                </div>
                {shouldShowAutomaticRequirements ? (
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Equipement calcule</th>
                        <th>Besoin</th>
                        <th>Disponible</th>
                        <th>Ecart</th>
                        <th>Statut</th>
                      </tr>
                    </thead>
                    <tbody>
                      {automaticRequirementRows.map((row) => (
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
                ) : (
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Equipement</th>
                        <th>Categorie</th>
                        <th>Puissance unitaire</th>
                        <th>Demande</th>
                        <th>Utilisable</th>
                        <th>A limiter</th>
                        <th>Statut</th>
                      </tr>
                    </thead>
                    <tbody>
                      {equipmentAnalysisRows.map((item) => (
                        <tr key={`${item.name}-${item.category}-${item.reason}`}>
                          <td>{item.name}</td>
                          <td>{item.category || '-'}</td>
                          <td>{formatNumber(item.unit_power_watts)} W</td>
                          <td>{item.requested_quantity}</td>
                          <td>{item.supported_quantity}</td>
                          <td>{item.unsupported_quantity}</td>
                          <td>{humanizeStatus(item.status)}</td>
                        </tr>
                      ))}
                      {equipmentAnalysisRows.length === 0 ? (
                        <tr>
                          <td colSpan={7}>Aucun equipement enregistre sur ce site.</td>
                        </tr>
                      ) : null}
                    </tbody>
                  </table>
                )}
              </section>
            </div>
          ) : null}

          <section className="table-panel">
            <div className="table-panel__header">
              <div>
                <h3>Charges actuellement enregistrees sur le site</h3>
                <p className="panel-message">
                  Cette liste contient les charges reelles du site a alimenter. C'est elle qui est
                  analysee dans le tableau juste au-dessus.
                </p>
              </div>
              <Link className="button-link button-link--ghost" to={`/sites/${data.site_id}`}>
                Modifier ces charges
              </Link>
            </div>
            {possibleMisclassifiedHardware.length ? (
              <div className="list-card list-card--warning">
                <strong>Materiel probablement classe comme charge</strong>
                <p>
                  {possibleMisclassifiedHardware.map((item) => item.name).join(', ')} ressemble a du
                  materiel solaire disponible. Ici, il est compte comme une consommation electrique
                  a alimenter.
                </p>
                <a className="text-link" href="#inventaire-materiel">
                  Le declarer dans l'inventaire disponible
                </a>
              </div>
            ) : null}
            <table className="data-table">
              <thead>
                <tr>
                  <th>Equipement</th>
                  <th>Categorie</th>
                  <th>Puissance</th>
                  <th>Quantite</th>
                  <th>Critique</th>
                </tr>
              </thead>
              <tbody>
                {siteEquipment.map((item) => (
                  <tr key={item.id}>
                    <td>{item.name}</td>
                    <td>{item.category}</td>
                    <td>{formatNumber(item.power_watts)} W</td>
                    <td>{item.quantity}</td>
                    <td>{item.is_critical ? 'Oui' : 'Non'}</td>
                  </tr>
                ))}
                {siteEquipment.length === 0 ? (
                  <tr>
                    <td colSpan={5}>Aucun equipement enregistre pour ce site.</td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          </section>

          {componentInventoryPlan ? (
            <section className="table-panel">
              <div className="table-panel__header">
                <h3>Ecarts entre besoin du systeme et materiel disponible</h3>
                <a className="button-link button-link--ghost button-link--small" href="#inventaire-materiel">
                  Modifier l'inventaire disponible
                </a>
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

          <details className="simple-details">
            <summary>Afficher les details techniques</summary>
            <div className="simple-details__content simple-details__content--stack">
              <div className="page-grid">
                <section className="panel">
                  <h3>Configuration recommandee</h3>
                  <table className="data-table">
                    <tbody>
                      <tr>
                        <th>Panneaux</th>
                        <td>{result.number_of_panels}</td>
                      </tr>
                      <tr>
                        <th>Batteries</th>
                        <td>{result.number_of_batteries}</td>
                      </tr>
                      <tr>
                        <th>Capacite batterie</th>
                        <td>{formatNumber(result.required_battery_capacity_ah)} Ah</td>
                      </tr>
                      <tr>
                        <th>Courant regulateur</th>
                        <td>{formatNumber(result.controller_current_a)} A</td>
                      </tr>
                      <tr>
                        <th>Protection electrique</th>
                        <td>{formatNumber(result.protection_cost)} USD</td>
                      </tr>
                    </tbody>
                  </table>
                </section>

                <section className="panel">
                  <h3>Protection et mise a la terre</h3>
                  <div className="stack-list">
                    <div className="list-card">
                      <strong>Liaison DC recommandee</strong>
                      <p>{formatNumber(result.dc_cable_section_mm2)} mm2 · protection {formatNumber(result.dc_breaker_rating_a)} A</p>
                    </div>
                    <div className="list-card">
                      <strong>Liaison AC recommandee</strong>
                      <p>{formatNumber(result.ac_cable_section_mm2)} mm2 · protection {formatNumber(result.ac_breaker_rating_a)} A</p>
                    </div>
                    <div className="list-card">
                      <strong>Mise a la terre</strong>
                      <p>{humanizeStatus(result.grounding_status)} · cible {formatNumber(result.recommended_earthing_resistance_ohm)} ohm</p>
                    </div>
                  </div>
                </section>
              </div>

              {equipmentPlan?.unsupported_equipment.length ? (
                <section className="table-panel">
                  <div className="table-panel__header">
                    <h3>Equipements a reduire ou a delester</h3>
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
            </div>
          </details>
        </>
      ) : (
        <section className="panel">
          <h3>Aucun resultat calcule</h3>
          <p>
            Ajoute des charges du site ou renseigne une puissance critique, puis lance le calcul
            pour obtenir l'etat de sortie.
          </p>
        </section>
      )}
    </section>
  )
}
