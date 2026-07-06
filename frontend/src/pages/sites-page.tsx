import { SectionTitle } from '../components/section-title'
import { useProtectedQuery } from '../hooks/use-protected-query'
import { createSite, listSites, updateSite } from '../services/site-service'
import { useAuth } from '../hooks/use-auth'
import { canManageSiteData } from '../lib/permissions'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import type { SiteSummary } from '../types/domain'

function computeAvailableArea(form: typeof initialForm) {
  const freeArea =
    form.total_area_m2 -
    form.tower_area_m2 -
    form.rack_area_m2 -
    form.generator_area_m2 -
    form.other_blocked_area_m2
  return Math.max(freeArea, 0) * form.usable_area_ratio
}

const initialForm = {
  name: '',
  city: 'Goma',
  country: 'RDC',
  site_type: 'Site telecom hybride',
  description: '',
  latitude: -1.679,
  longitude: 29.222,
  operating_hours_per_day: 24,
  autonomy_days: 1,
  target_backup_hours: 1.5,
  solar_irradiation_hours: 5,
  system_efficiency: 0.8,
  system_voltage: 48,
  total_area_m2: 0,
  tower_area_m2: 0,
  rack_area_m2: 0,
  generator_area_m2: 0,
  other_blocked_area_m2: 0,
  available_area_m2: 0,
  usable_area_ratio: 0.9,
  layout_length_m: 0,
  layout_width_m: 0,
  snel_available: true,
  generator_available: true,
  generator_failure_scenario: true,
}

function formFromSite(site: SiteSummary): typeof initialForm {
  return {
    name: site.name,
    city: site.city,
    country: site.country,
    site_type: site.site_type,
    description: site.description ?? '',
    latitude: site.latitude ?? 0,
    longitude: site.longitude ?? 0,
    operating_hours_per_day: site.operating_hours_per_day ?? 24,
    autonomy_days: site.autonomy_days ?? 1,
    target_backup_hours: site.target_backup_hours,
    solar_irradiation_hours: site.solar_irradiation_hours ?? 5,
    system_efficiency: site.system_efficiency ?? 0.8,
    system_voltage: site.system_voltage ?? 48,
    total_area_m2: site.total_area_m2,
    tower_area_m2: site.tower_area_m2,
    rack_area_m2: site.rack_area_m2,
    generator_area_m2: site.generator_area_m2,
    other_blocked_area_m2: site.other_blocked_area_m2,
    available_area_m2: site.available_area_m2,
    usable_area_ratio: site.usable_area_ratio ?? 1,
    layout_length_m: site.layout_length_m ?? 0,
    layout_width_m: site.layout_width_m ?? 0,
    snel_available: site.snel_available ?? true,
    generator_available: site.generator_available ?? true,
    generator_failure_scenario: site.generator_failure_scenario ?? true,
  }
}

export function SitesPage() {
  const { token, user } = useAuth()
  const { data: sites, loading, error, setData } = useProtectedQuery({
    fallbackData: [],
    queryKey: 'sites',
    request: listSites,
  })
  const [form, setForm] = useState(initialForm)
  const [submitting, setSubmitting] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [editingSiteId, setEditingSiteId] = useState<number | null>(null)
  const [manualAvailableArea, setManualAvailableArea] = useState(false)
  const canEdit = canManageSiteData(user?.role)
  const computedAvailableArea = computeAvailableArea(form)

  function startEditing(site: SiteSummary) {
    const siteForm = formFromSite(site)
    setEditingSiteId(site.id)
    setForm(siteForm)
    setManualAvailableArea(
      site.available_area_m2 > 0 &&
        Math.abs(site.available_area_m2 - computeAvailableArea(siteForm)) > 0.01,
    )
    setMessage(null)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  function stopEditing() {
    setEditingSiteId(null)
    setForm(initialForm)
    setManualAvailableArea(false)
    setMessage(null)
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!token) {
      setMessage('Connexion requise pour enregistrer un site.')
      return
    }

    setSubmitting(true)
    setMessage(null)
    try {
      const payload = {
        ...form,
        available_area_m2: manualAvailableArea ? form.available_area_m2 : computedAvailableArea,
      }

      if (editingSiteId !== null) {
        const updated = await updateSite(token, editingSiteId, payload)
        setData(sites.map((site) => (site.id === updated.id ? updated : site)))
        setMessage('Site modifie avec succes.')
        setEditingSiteId(null)
      } else {
        const created = await createSite(token, payload)
        setData([created, ...sites])
        setMessage('Site cree avec succes.')
      }
      setForm(initialForm)
      setManualAvailableArea(false)
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Enregistrement impossible.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <section className="page">
      <SectionTitle
        eyebrow="Sites telecom"
        title="Base de travail pour les contraintes reelles"
        text="Chaque site devra porter la surface disponible, les heures solaires, la tension systeme et le scenario de panne du groupe."
      />

      <div className="page-grid">
        <section className="panel">
          <h3>{canEdit ? (editingSiteId !== null ? 'Modifier le site' : 'Nouveau site') : 'Consultation des sites'}</h3>
          {canEdit ? (
          <form className="form-grid" onSubmit={handleSubmit}>
            <label>
              <span>Nom du site</span>
              <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
            </label>
            <label>
              <span>Ville</span>
              <input value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} required />
            </label>
            <label>
              <span>Pays</span>
              <input value={form.country} onChange={(e) => setForm({ ...form, country: e.target.value })} required />
            </label>
            <label>
              <span>Type de site</span>
              <input value={form.site_type} onChange={(e) => setForm({ ...form, site_type: e.target.value })} required />
            </label>
            <label>
              <span>Surface totale du site (m2)</span>
              <input
                type="number"
                min="0"
                step="0.1"
                value={form.total_area_m2}
                onChange={(e) => setForm({ ...form, total_area_m2: Number(e.target.value) })}
              />
            </label>
            <label>
              <span>Surface pylone (m2)</span>
              <input type="number" min="0" step="0.1" value={form.tower_area_m2} onChange={(e) => setForm({ ...form, tower_area_m2: Number(e.target.value) })} />
            </label>
            <label>
              <span>Surface rack (m2)</span>
              <input type="number" min="0" step="0.1" value={form.rack_area_m2} onChange={(e) => setForm({ ...form, rack_area_m2: Number(e.target.value) })} />
            </label>
            <label>
              <span>Surface groupe (m2)</span>
              <input type="number" min="0" step="0.1" value={form.generator_area_m2} onChange={(e) => setForm({ ...form, generator_area_m2: Number(e.target.value) })} />
            </label>
            <label>
              <span>Surface bloquee diverse (m2)</span>
              <input type="number" min="0" step="0.1" value={form.other_blocked_area_m2} onChange={(e) => setForm({ ...form, other_blocked_area_m2: Number(e.target.value) })} />
            </label>
            <label>
              <span>Ratio exploitable</span>
              <input type="number" min="0.1" max="1" step="0.01" value={form.usable_area_ratio} onChange={(e) => setForm({ ...form, usable_area_ratio: Number(e.target.value) })} />
            </label>
            <label className="checkbox-field">
              <input
                type="checkbox"
                checked={manualAvailableArea}
                onChange={(e) => {
                  const manual = e.target.checked
                  setManualAvailableArea(manual)
                  if (manual) {
                    setForm({ ...form, available_area_m2: computedAvailableArea })
                  }
                }}
              />
              <span>Saisir directement la surface utile</span>
            </label>
            <label>
              <span>Surface utile (m2)</span>
              <input
                type="number"
                min="0"
                step="0.1"
                value={manualAvailableArea ? form.available_area_m2 : computedAvailableArea}
                readOnly={!manualAvailableArea}
                onChange={(e) => setForm({ ...form, available_area_m2: Number(e.target.value) })}
              />
              <small className="field-help">
                {manualAvailableArea
                  ? 'Entrez ici la surface réellement utilisable pour les panneaux.'
                  : 'Calcul automatique : (surface totale - zones occupées) × ratio exploitable.'}
              </small>
            </label>
            <label>
              <span>Longueur de la zone d'implantation (m)</span>
              <input
                type="number"
                min="0"
                step="0.1"
                value={form.layout_length_m}
                onChange={(e) => setForm({ ...form, layout_length_m: Number(e.target.value) })}
              />
            </label>
            <label>
              <span>Largeur de la zone d'implantation (m)</span>
              <input
                type="number"
                min="0"
                step="0.1"
                value={form.layout_width_m}
                onChange={(e) => setForm({ ...form, layout_width_m: Number(e.target.value) })}
              />
              <small className="field-help">
                La longueur × largeur ne doit pas dépasser la surface utile.
              </small>
            </label>
            <label>
              <span>Backup cible (h)</span>
              <input
                type="number"
                min="1"
                step="0.1"
                value={form.target_backup_hours}
                onChange={(e) => setForm({ ...form, target_backup_hours: Number(e.target.value) })}
              />
            </label>
            <label>
              <span>Heures solaires</span>
              <input
                type="number"
                min="1"
                step="0.1"
                value={form.solar_irradiation_hours}
                onChange={(e) => setForm({ ...form, solar_irradiation_hours: Number(e.target.value) })}
              />
            </label>
            <label>
              <span>Rendement systeme</span>
              <input
                type="number"
                min="0.1"
                max="1"
                step="0.01"
                value={form.system_efficiency}
                onChange={(e) => setForm({ ...form, system_efficiency: Number(e.target.value) })}
              />
            </label>
            <label className="form-grid__full">
              <span>Description</span>
              <textarea
                rows={3}
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
              />
            </label>
            <label className="checkbox-field">
              <input
                type="checkbox"
                checked={form.snel_available}
                onChange={(e) => setForm({ ...form, snel_available: e.target.checked })}
              />
              <span>SNEL disponible sur site</span>
            </label>
            <label className="checkbox-field">
              <input
                type="checkbox"
                checked={form.generator_available}
                onChange={(e) => setForm({ ...form, generator_available: e.target.checked })}
              />
              <span>Groupe electrogene disponible sur site</span>
            </label>
            <label className="checkbox-field">
              <input
                type="checkbox"
                checked={form.generator_failure_scenario}
                onChange={(e) => setForm({ ...form, generator_failure_scenario: e.target.checked })}
              />
              <span>Calcul en cas de defaillance du groupe</span>
            </label>
            <div className="form-actions form-grid__full">
              <button className="button-link button-link--solid" type="submit" disabled={submitting}>
                {submitting ? 'Enregistrement...' : editingSiteId !== null ? 'Enregistrer les modifications' : 'Creer le site'}
              </button>
              {editingSiteId !== null ? (
                <button className="button-link button-link--ghost" type="button" onClick={stopEditing} disabled={submitting}>
                  Annuler
                </button>
              ) : null}
              {message ? <p className="form-message">{message}</p> : null}
            </div>
          </form>
          ) : (
            <p>Votre role est en lecture seule pour les donnees terrain.</p>
          )}
        </section>

        <section className="panel">
          <h3>Etat de connexion</h3>
          <p>{loading ? 'Chargement des sites...' : 'Liste prete pour consultation.'}</p>
          {error ? <p className="form-error">API indisponible ou aucune donnee chargee.</p> : null}
        </section>
      </div>

      <div className="table-panel">
        <table className="data-table">
          <thead>
            <tr>
              <th>Site</th>
              <th>Localisation</th>
              <th>Type</th>
              <th>Surface utile</th>
              <th>Backup cible</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {sites.map((site) => (
              <tr key={site.id}>
                <td>{site.name}</td>
                <td>
                  {site.city}, {site.country}
                </td>
                <td>{site.site_type}</td>
                <td>{site.available_area_m2} m2</td>
                <td>{site.target_backup_hours} h</td>
                <td>
                  <div className="table-actions table-actions--links">
                    {canEdit ? (
                      <button className="text-link text-link--button" type="button" onClick={() => startEditing(site)}>
                        Modifier
                      </button>
                    ) : null}
                    <Link className="text-link" to={`/sites/${site.id}`}>
                      Gerer les equipements
                    </Link>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}
