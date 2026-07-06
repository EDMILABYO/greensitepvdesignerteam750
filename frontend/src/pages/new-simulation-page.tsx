import { SectionTitle } from '../components/section-title'
import { useProtectedQuery } from '../hooks/use-protected-query'
import {
  createSimulation,
  getSimulation,
  updateSimulation,
} from '../services/simulation-service'
import { listSites } from '../services/site-service'
import { useAuth } from '../hooks/use-auth'
import { canManageSimulations } from '../lib/permissions'
import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'

const initialForm = {
  site_id: 1,
  critical_active_power_w: 0,
  backup_time_hours: 1.5,
  power_factor: 0.8,
  air_conditioner_power_w: 0,
  air_conditioner_is_critical: false,
  other_critical_power_w: 0,
  other_non_critical_power_w: 0,
  panel_power_watts: 550,
  panel_type: 'Monocristallin',
  panel_length_m: 2.28,
  panel_width_m: 1.13,
  panel_area_m2: 2.58,
  panel_spacing_factor: 1.2,
  installed_panel_count: 0,
  battery_capacity_ah: 200,
  battery_voltage: 12,
  battery_type: 'LiFePO4',
  battery_energy_kwh: 2.4,
  installed_battery_count: 0,
  installed_inverter_power_watts: 0,
  installed_controller_count: 0,
  installed_controller_current_a: 0,
  installed_dc_spd_count: 0,
  installed_ac_spd_count: 0,
  installed_earthing_kit_count: 0,
  battery_dod: 0.8,
  battery_efficiency: 0.95,
  controller_efficiency: 0.96,
  inverter_efficiency: 0.93,
  cable_loss_factor: 0.03,
  dc_cable_length_m: 20,
  ac_cable_length_m: 30,
  dc_voltage_drop_limit_percent: 3,
  ac_voltage_drop_limit_percent: 5,
  temperature_loss_factor: 0.05,
  dust_loss_factor: 0.03,
  safety_factor: 1.25,
  lightning_protection_required: true,
  dc_spd_required: true,
  ac_spd_required: true,
  earthing_required: true,
  earthing_resistance_target_ohm: 5,
  earthing_resistance_measured_ohm: 0,
  panel_unit_price: 150,
  battery_unit_price: 250,
  inverter_price: 500,
  controller_price: 300,
  air_conditioner_price: 0,
  accessories_price: 400,
  protection_price: 250,
  installation_price: 500,
  labor_price: 500,
  maintenance_price: 0,
  snel_operating_cost: 0,
  generator_operating_cost: 0,
}

export function NewSimulationPage() {
  const { simulationId } = useParams()
  const numericSimulationId = simulationId ? Number(simulationId) : null
  const { token, user } = useAuth()
  const navigate = useNavigate()
  const isEditMode = numericSimulationId !== null && !Number.isNaN(numericSimulationId)
  const { data: sites } = useProtectedQuery({
    fallbackData: [],
    queryKey: 'sites-simulation-form',
    request: listSites,
  })
  const { data: existingSimulation, loading: loadingSimulation } = useProtectedQuery({
    fallbackData: null,
    queryKey: isEditMode ? `simulation-edit-${numericSimulationId}` : 'simulation-edit-none',
    request: (authToken) =>
      isEditMode && numericSimulationId
        ? getSimulation(authToken, numericSimulationId)
        : Promise.resolve(null),
  })
  const [form, setForm] = useState(initialForm)
  const [message, setMessage] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    if (existingSimulation) {
      const { result: _result, id: _id, user_id: _userId, created_at: _createdAt, ...simulationForm } =
        existingSimulation
      setForm(simulationForm)
    }
  }, [existingSimulation])

  if (!canManageSimulations(user?.role)) {
    return (
      <section className="page">
        <div className="panel">
          <h3>Acces refuse</h3>
          <p>Votre role ne permet pas de creer ou lancer un nouveau dimensionnement.</p>
        </div>
      </section>
    )
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!token) {
      setMessage('Connexion requise pour enregistrer une simulation.')
      return
    }

    setSubmitting(true)
    setMessage(null)
    try {
      if (isEditMode && numericSimulationId) {
        const updated = await updateSimulation(token, numericSimulationId, form)
        setMessage('Simulation modifiee. Redirection vers le detail...')
        navigate(`/simulations/${updated.id}`)
      } else {
        const created = await createSimulation(token, form)
        setMessage('Simulation creee. Redirection vers le detail...')
        navigate(`/simulations/${created.id}`)
      }
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Creation impossible.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <section className="page">
      <SectionTitle
        eyebrow="Nouveau calcul"
        title={isEditMode ? 'Modification de la simulation' : 'Dimensionnement du back-up photovoltaque HAYATCOM'}
        text={
          isEditMode
            ? "Ajuste les charges critiques, l'autonomie voulue et les parametres de secours avant de relancer le calcul."
            : "Commence par le besoin metier reel: quelles charges critiques doivent rester alimentees, et pendant combien de temps en cas d'absence SNEL et de non-demarrage du groupe."
        }
      />

      {isEditMode && loadingSimulation ? <p className="panel-message">Chargement de la simulation...</p> : null}

      <div className="page-grid">
        <section className="panel">
          <h3>Mode de fonctionnement HAYATCOM</h3>
          <div className="stack-list">
            <div className="list-card">
              <strong>Sources considerees</strong>
              <p>SNEL, panneaux solaires et groupe electrogene.</p>
            </div>
            <div className="list-card">
              <strong>Scenario de back-up</strong>
              <p>Si la SNEL est absente et que le groupe ne demarre pas automatiquement, le systeme solaire prend le relais sur les charges critiques.</p>
            </div>
            <div className="list-card">
              <strong>Deux donnees d'entree essentielles</strong>
              <p>La puissance des charges critiques a maintenir et le temps de secours souhaite.</p>
            </div>
            <div className="list-card">
              <strong>Etat de sortie attendu</strong>
              <p>Puissance active, puissance apparente, regulateur, onduleur, batteries, panneaux, climatisation critique, baie radio et protections electriques.</p>
            </div>
          </div>
        </section>

        <section className="panel">
          <h3>1. Charges critiques et autonomie</h3>
          <form className="form-grid" onSubmit={handleSubmit}>
            <label className="form-grid__full">
              <span>Site cible</span>
              <select
                value={form.site_id}
                onChange={(e) => setForm({ ...form, site_id: Number(e.target.value) })}
              >
                {sites.map((site) => (
                  <option key={site.id} value={site.id}>
                    {site.name}
                  </option>
                ))}
              </select>
            </label>

            <div className="form-grid__full list-card list-card--accent">
              <strong>Saisie recommandee</strong>
              <p>
                Si tu connais deja les equipements critiques du site, commence par les declarer dans
                les charges du site. Ici, tu peux ensuite saisir la synthese energetique necessaire
                au back-up.
              </p>
              <div className="form-actions" style={{ marginTop: '0.75rem' }}>
                <Link className="button-link button-link--ghost" to={`/sites/${form.site_id}`}>
                  Ouvrir les charges du site
                </Link>
              </div>
            </div>

            <label>
              <span>Puissance active critique totale (W)</span>
              <input
                type="number"
                min="0"
                value={form.critical_active_power_w}
                onChange={(e) => setForm({ ...form, critical_active_power_w: Number(e.target.value) })}
                required
              />
            </label>

            <label>
              <span>Temps de secours vise (h)</span>
              <input
                type="number"
                min="0.1"
                step="0.1"
                value={form.backup_time_hours}
                onChange={(e) => setForm({ ...form, backup_time_hours: Number(e.target.value) })}
              />
            </label>

            <label>
              <span>Facteur de puissance</span>
              <input
                type="number"
                min="0.1"
                max="1"
                step="0.01"
                value={form.power_factor}
                onChange={(e) => setForm({ ...form, power_factor: Number(e.target.value) })}
              />
            </label>

            <label>
              <span>Climatiseur critique (W)</span>
              <input
                type="number"
                min="0"
                value={form.air_conditioner_power_w}
                onChange={(e) => setForm({ ...form, air_conditioner_power_w: Number(e.target.value) })}
              />
            </label>

            <label>
              <span>Baie radio et autres charges critiques additionnelles (W)</span>
              <input
                type="number"
                min="0"
                value={form.other_critical_power_w}
                onChange={(e) => setForm({ ...form, other_critical_power_w: Number(e.target.value) })}
              />
            </label>

            <label>
              <span>Charges non critiques delestables (W)</span>
              <input
                type="number"
                min="0"
                value={form.other_non_critical_power_w}
                onChange={(e) => setForm({ ...form, other_non_critical_power_w: Number(e.target.value) })}
              />
            </label>

            <label className="checkbox-field form-grid__full">
              <input
                type="checkbox"
                checked={form.air_conditioner_is_critical}
                onChange={(e) => setForm({ ...form, air_conditioner_is_critical: e.target.checked })}
              />
              <span>Le climatiseur fait partie des charges critiques</span>
            </label>

            <div className="form-grid__full list-card">
              <strong>Conseil de saisie</strong>
              <p>
                Si la charge critique totale n'est pas encore connue, declare d'abord les charges du
                site comme BTS, radio, routeur, transmission, climatisation et eclairage, puis
                reviens ici pour consolider la puissance active.
              </p>
            </div>

            <div className="form-grid__full simple-form-section">
              <h4>2. Composants et stock de back-up disponibles</h4>
              <div className="form-grid">
                <label>
                  <span>Puissance panneau (Wc)</span>
                  <input
                    type="number"
                    min="1"
                    value={form.panel_power_watts}
                    onChange={(e) => setForm({ ...form, panel_power_watts: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Nombre de panneaux disponibles</span>
                  <input
                    type="number"
                    min="0"
                    value={form.installed_panel_count}
                    onChange={(e) => setForm({ ...form, installed_panel_count: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Batterie (Ah)</span>
                  <input
                    type="number"
                    min="1"
                    value={form.battery_capacity_ah}
                    onChange={(e) => setForm({ ...form, battery_capacity_ah: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Nombre de batteries disponibles</span>
                  <input
                    type="number"
                    min="0"
                    value={form.installed_battery_count}
                    onChange={(e) => setForm({ ...form, installed_battery_count: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Energie batterie (kWh)</span>
                  <input
                    type="number"
                    min="0.1"
                    step="0.1"
                    value={form.battery_energy_kwh}
                    onChange={(e) => setForm({ ...form, battery_energy_kwh: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Onduleur disponible (W)</span>
                  <input
                    type="number"
                    min="0"
                    value={form.installed_inverter_power_watts}
                    onChange={(e) => setForm({ ...form, installed_inverter_power_watts: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Nombre de regulateurs disponibles</span>
                  <input
                    type="number"
                    min="0"
                    value={form.installed_controller_count}
                    onChange={(e) => setForm({ ...form, installed_controller_count: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Courant d'un regulateur (A)</span>
                  <input
                    type="number"
                    min="0"
                    value={form.installed_controller_current_a}
                    onChange={(e) => setForm({ ...form, installed_controller_current_a: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Parafoudres DC disponibles</span>
                  <input
                    type="number"
                    min="0"
                    value={form.installed_dc_spd_count}
                    onChange={(e) => setForm({ ...form, installed_dc_spd_count: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Parafoudres AC disponibles</span>
                  <input
                    type="number"
                    min="0"
                    value={form.installed_ac_spd_count}
                    onChange={(e) => setForm({ ...form, installed_ac_spd_count: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Kits de mise a la terre disponibles</span>
                  <input
                    type="number"
                    min="0"
                    value={form.installed_earthing_kit_count}
                    onChange={(e) => setForm({ ...form, installed_earthing_kit_count: Number(e.target.value) })}
                  />
                </label>
                <label>
                  <span>Prix onduleur</span>
                  <input
                    type="number"
                    min="0"
                    value={form.inverter_price}
                    onChange={(e) => setForm({ ...form, inverter_price: Number(e.target.value) })}
                  />
                </label>
              </div>
            </div>

            <details className="simple-details form-grid__full">
              <summary>Afficher les reglages techniques avances</summary>
              <div className="form-grid simple-details__content">
                <label>
                  <span>Longueur panneau (m)</span>
                  <input type="number" min="0.1" step="0.01" value={form.panel_length_m} onChange={(e) => setForm({ ...form, panel_length_m: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Largeur panneau (m)</span>
                  <input type="number" min="0.1" step="0.01" value={form.panel_width_m} onChange={(e) => setForm({ ...form, panel_width_m: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Surface panneau (m2)</span>
                  <input type="number" min="0.1" step="0.01" value={form.panel_area_m2} onChange={(e) => setForm({ ...form, panel_area_m2: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Facteur espacement</span>
                  <input type="number" min="1" step="0.01" value={form.panel_spacing_factor} onChange={(e) => setForm({ ...form, panel_spacing_factor: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Rendement batterie</span>
                  <input type="number" min="0.1" max="1" step="0.01" value={form.battery_efficiency} onChange={(e) => setForm({ ...form, battery_efficiency: Number(e.target.value) })} />
                </label>
                <label>
                  <span>DoD</span>
                  <input type="number" min="0.1" max="1" step="0.01" value={form.battery_dod} onChange={(e) => setForm({ ...form, battery_dod: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Rendement regulateur</span>
                  <input type="number" min="0.1" max="1" step="0.01" value={form.controller_efficiency} onChange={(e) => setForm({ ...form, controller_efficiency: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Rendement onduleur</span>
                  <input type="number" min="0.1" max="1" step="0.01" value={form.inverter_efficiency} onChange={(e) => setForm({ ...form, inverter_efficiency: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Pertes cables</span>
                  <input type="number" min="0" max="1" step="0.01" value={form.cable_loss_factor} onChange={(e) => setForm({ ...form, cable_loss_factor: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Longueur cable DC (m)</span>
                  <input type="number" min="0" step="1" value={form.dc_cable_length_m} onChange={(e) => setForm({ ...form, dc_cable_length_m: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Longueur cable AC (m)</span>
                  <input type="number" min="0" step="1" value={form.ac_cable_length_m} onChange={(e) => setForm({ ...form, ac_cable_length_m: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Chute tension DC max (%)</span>
                  <input type="number" min="1" max="10" step="0.5" value={form.dc_voltage_drop_limit_percent} onChange={(e) => setForm({ ...form, dc_voltage_drop_limit_percent: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Chute tension AC max (%)</span>
                  <input type="number" min="1" max="10" step="0.5" value={form.ac_voltage_drop_limit_percent} onChange={(e) => setForm({ ...form, ac_voltage_drop_limit_percent: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Pertes temperature</span>
                  <input type="number" min="0" max="1" step="0.01" value={form.temperature_loss_factor} onChange={(e) => setForm({ ...form, temperature_loss_factor: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Pertes poussiere</span>
                  <input type="number" min="0" max="1" step="0.01" value={form.dust_loss_factor} onChange={(e) => setForm({ ...form, dust_loss_factor: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Facteur securite</span>
                  <input type="number" min="1" step="0.01" value={form.safety_factor} onChange={(e) => setForm({ ...form, safety_factor: Number(e.target.value) })} />
                </label>
                <label className="checkbox-field form-grid__full">
                  <input type="checkbox" checked={form.lightning_protection_required} onChange={(e) => setForm({ ...form, lightning_protection_required: e.target.checked })} />
                  <span>Prevoir la protection foudre du pylone et des equipements BTS</span>
                </label>
                <label className="checkbox-field">
                  <input type="checkbox" checked={form.dc_spd_required} onChange={(e) => setForm({ ...form, dc_spd_required: e.target.checked })} />
                  <span>Parafoudre DC requis</span>
                </label>
                <label className="checkbox-field">
                  <input type="checkbox" checked={form.ac_spd_required} onChange={(e) => setForm({ ...form, ac_spd_required: e.target.checked })} />
                  <span>Parafoudre AC requis</span>
                </label>
                <label className="checkbox-field">
                  <input type="checkbox" checked={form.earthing_required} onChange={(e) => setForm({ ...form, earthing_required: e.target.checked })} />
                  <span>Mise a la terre requise</span>
                </label>
                <label>
                  <span>Resistance de terre cible (ohm)</span>
                  <input type="number" min="0.1" step="0.1" value={form.earthing_resistance_target_ohm} onChange={(e) => setForm({ ...form, earthing_resistance_target_ohm: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Resistance de terre mesuree (ohm)</span>
                  <input type="number" min="0" step="0.1" value={form.earthing_resistance_measured_ohm} onChange={(e) => setForm({ ...form, earthing_resistance_measured_ohm: Number(e.target.value) })} />
                </label>
              </div>
            </details>

            <details className="simple-details form-grid__full">
              <summary>Afficher les couts et prix</summary>
              <div className="form-grid simple-details__content">
                <label>
                  <span>Prix panneau</span>
                  <input type="number" min="0" value={form.panel_unit_price} onChange={(e) => setForm({ ...form, panel_unit_price: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Prix batterie</span>
                  <input type="number" min="0" value={form.battery_unit_price} onChange={(e) => setForm({ ...form, battery_unit_price: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Prix regulateur</span>
                  <input type="number" min="0" value={form.controller_price} onChange={(e) => setForm({ ...form, controller_price: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Prix climatiseur</span>
                  <input type="number" min="0" value={form.air_conditioner_price} onChange={(e) => setForm({ ...form, air_conditioner_price: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Accessoires</span>
                  <input type="number" min="0" value={form.accessories_price} onChange={(e) => setForm({ ...form, accessories_price: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Protection electrique</span>
                  <input type="number" min="0" value={form.protection_price} onChange={(e) => setForm({ ...form, protection_price: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Installation</span>
                  <input type="number" min="0" value={form.installation_price} onChange={(e) => setForm({ ...form, installation_price: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Maintenance</span>
                  <input type="number" min="0" value={form.maintenance_price} onChange={(e) => setForm({ ...form, maintenance_price: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Cout exploitation SNEL</span>
                  <input type="number" min="0" value={form.snel_operating_cost} onChange={(e) => setForm({ ...form, snel_operating_cost: Number(e.target.value) })} />
                </label>
                <label>
                  <span>Cout exploitation groupe</span>
                  <input type="number" min="0" value={form.generator_operating_cost} onChange={(e) => setForm({ ...form, generator_operating_cost: Number(e.target.value) })} />
                </label>
              </div>
            </details>

            <div className="form-actions form-grid__full">
              <button className="button-link button-link--solid" type="submit" disabled={submitting}>
                {submitting
                  ? isEditMode
                    ? 'Mise a jour...'
                    : 'Creation...'
                  : isEditMode
                    ? 'Enregistrer les modifications'
                    : 'Creer la simulation'}
              </button>
              {message ? <p className="form-message">{message}</p> : null}
            </div>
          </form>
        </section>

        <section className="panel">
          <h3>Parcours de calcul</h3>
          <div className="stack-list">
            <div className="list-card">
              <strong>Etape 1</strong>
              <p>Choisir le site et identifier les charges critiques qui doivent rester alimentees.</p>
            </div>
            <div className="list-card">
              <strong>Etape 2</strong>
              <p>Saisir la puissance active critique, le temps de secours, puis le stock de back-up disponible.</p>
            </div>
            <div className="list-card">
              <strong>Etape 3</strong>
              <p>Lancer le calcul pour obtenir la puissance apparente, les panneaux, le regulateur, l'onduleur, les batteries et les protections.</p>
            </div>
          </div>
        </section>
      </div>
    </section>
  )
}
