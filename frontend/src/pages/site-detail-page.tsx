import { Link, useParams } from 'react-router-dom'
import { SectionTitle } from '../components/section-title'
import { useProtectedQuery } from '../hooks/use-protected-query'
import { useAuth } from '../hooks/use-auth'
import { canManageSimulations, canManageSiteData } from '../lib/permissions'
import {
  createEquipment,
  deleteEquipment,
  listEquipment,
  updateEquipment,
} from '../services/equipment-service'
import { listSites } from '../services/site-service'
import { useMemo, useState } from 'react'
import type { EquipmentItem } from '../types/domain'

const equipmentFormInitial = {
  name: '',
  category: 'Radio',
  power_watts: 0,
  quantity: 1,
  hours_per_day: 24,
  is_critical: true,
  notes: '',
  position_x_m: 0,
  position_y_m: 0,
  footprint_length_m: 0,
  footprint_width_m: 0,
}

function isSystemHardware(name: string, category: string) {
  const value = `${name} ${category}`
    .toLocaleLowerCase('fr')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
  return /panneau|batterie|onduleur|regulateur|parafoudre|mise a la terre/.test(value)
}

export function SiteDetailPage() {
  const { siteId } = useParams()
  const numericSiteId = Number(siteId)
  const { token, user } = useAuth()
  const { data: sites } = useProtectedQuery({
    fallbackData: [],
    queryKey: 'site-detail-sites',
    request: listSites,
  })
  const fallbackEquipment: EquipmentItem[] = []
  const { data: equipment, setData, error } = useProtectedQuery({
    fallbackData: fallbackEquipment,
    queryKey: `equipment-${numericSiteId}`,
    request: (authToken) => listEquipment(authToken, numericSiteId),
  })
  const [form, setForm] = useState(equipmentFormInitial)
  const [message, setMessage] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [editingEquipmentId, setEditingEquipmentId] = useState<number | null>(null)
  const [editingForm, setEditingForm] = useState(equipmentFormInitial)
  const [actionEquipmentId, setActionEquipmentId] = useState<number | null>(null)
  const canEdit = canManageSiteData(user?.role)
  const canCreateSimulation = canManageSimulations(user?.role)

  const site = useMemo(() => sites.find((item) => item.id === numericSiteId) ?? null, [numericSiteId, sites])

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (isSystemHardware(form.name, form.category)) {
      setMessage(
        "Ce composant appartient a l'inventaire disponible et ne peut pas etre ajoute comme charge.",
      )
      return
    }
    if (!token) {
      setMessage('Connexion requise pour ajouter un equipement.')
      return
    }

    setSubmitting(true)
    setMessage(null)
    try {
      const created = await createEquipment(token, numericSiteId, form)
      setData([...equipment, created])
      setForm(equipmentFormInitial)
      setMessage('Equipement ajoute avec succes.')
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Ajout impossible.')
    } finally {
      setSubmitting(false)
    }
  }

  function startEditing(item: EquipmentItem) {
    setEditingEquipmentId(item.id)
    setEditingForm({
      name: item.name,
      category: item.category,
      power_watts: item.power_watts,
      quantity: item.quantity,
      hours_per_day: item.hours_per_day,
      is_critical: item.is_critical,
      notes: item.notes,
      position_x_m: item.position_x_m ?? 0,
      position_y_m: item.position_y_m ?? 0,
      footprint_length_m: item.footprint_length_m ?? 0,
      footprint_width_m: item.footprint_width_m ?? 0,
    })
    setMessage(null)
  }

  function cancelEditing() {
    setEditingEquipmentId(null)
    setEditingForm(equipmentFormInitial)
  }

  async function handleUpdateEquipment(equipmentId: number) {
    if (isSystemHardware(editingForm.name, editingForm.category)) {
      setMessage(
        "Ce composant appartient a l'inventaire disponible et ne peut pas rester dans les charges.",
      )
      return
    }
    if (!token) {
      setMessage('Connexion requise pour modifier un equipement.')
      return
    }

    setActionEquipmentId(equipmentId)
    setMessage(null)
    try {
      const updated = await updateEquipment(token, equipmentId, editingForm)
      setData(equipment.map((item) => (item.id === equipmentId ? updated : item)))
      setEditingEquipmentId(null)
      setEditingForm(equipmentFormInitial)
      setMessage('Equipement modifie avec succes.')
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Modification impossible.')
    } finally {
      setActionEquipmentId(null)
    }
  }

  async function handleDeleteEquipment(equipmentId: number) {
    if (!token) {
      setMessage('Connexion requise pour supprimer un equipement.')
      return
    }

    setActionEquipmentId(equipmentId)
    setMessage(null)
    try {
      await deleteEquipment(token, equipmentId)
      setData(equipment.filter((item) => item.id !== equipmentId))
      if (editingEquipmentId === equipmentId) {
        cancelEditing()
      }
      setMessage('Equipement supprime avec succes.')
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Suppression impossible.')
    } finally {
      setActionEquipmentId(null)
    }
  }

  if (!site) {
    return (
      <section className="page">
        <div className="panel">
          <h2>Site introuvable</h2>
          <p>Le site demande n'est pas encore disponible dans la source actuelle.</p>
        </div>
      </section>
    )
  }

  const layoutLength = site.layout_length_m ?? 0
  const layoutWidth = site.layout_width_m ?? 0
  const placedEquipment = equipment.filter(
    (item) => item.footprint_length_m > 0 && item.footprint_width_m > 0,
  )
  const occupiedArea = placedEquipment.reduce(
    (total, item) => total + item.footprint_length_m * item.footprint_width_m,
    0,
  )

  return (
    <section className="page">
      <SectionTitle
        eyebrow="Charges electriques du site"
        title={site.name}
        text="Declare ici uniquement les appareils qui consomment de l'energie : radio, BTS, routeur, climatisation ou eclairage."
      />

      <div className="page-grid">
        <section className="panel">
          <h3>Parcours simple</h3>
          <div className="stack-list">
            <div className="list-card">
              <strong>1. Ajouter les charges a alimenter</strong>
              <p>Renseigne les charges du site avec leur puissance et leur quantite.</p>
            </div>
            <div className="list-card">
              <strong>2. Verifier le contexte</strong>
              <p>Surface disponible: {site.available_area_m2} m2 · Backup cible: {site.target_backup_hours} h</p>
            </div>
            <div className="list-card">
              <strong>3. Lancer le calcul</strong>
              <p>Quand la liste est prete, passe au nouveau calcul pour obtenir le dimensionnement.</p>
            </div>
          </div>
          <div className="form-actions" style={{ marginTop: '1rem' }}>
            {canCreateSimulation ? (
              <Link className="button-link button-link--ghost" to="/simulations/new">
                Passer au calcul
              </Link>
            ) : (
              <p className="form-message">Votre role ne permet pas de lancer un nouveau calcul.</p>
            )}
          </div>
        </section>

        <section className="panel">
          <h3>{canEdit ? 'Ajouter une charge a alimenter' : 'Charges du site'}</h3>
          {canEdit ? (
            <>
            <div className="list-card list-card--warning">
              <strong>Panneaux, batteries et onduleurs</strong>
              <p>
                Ne les ajoutez pas ici : ils ne sont pas des charges. Leur quantite disponible se
                renseigne dans la simulation, sous « Inventaire du materiel disponible ».
              </p>
            </div>
            <form className="form-grid" onSubmit={handleSubmit}>
              <label>
                <span>Nom de la charge</span>
                <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
              </label>
              <label>
                <span>Categorie de charge</span>
                <input
                  value={form.category}
                  onChange={(e) => setForm({ ...form, category: e.target.value })}
                  placeholder="Radio, transmission, climatisation..."
                  required
                />
              </label>
              <label>
                <span>Puissance (W)</span>
                <input type="number" min="1" value={form.power_watts} onChange={(e) => setForm({ ...form, power_watts: Number(e.target.value) })} required />
              </label>
              <label>
                <span>Quantite</span>
                <input type="number" min="1" value={form.quantity} onChange={(e) => setForm({ ...form, quantity: Number(e.target.value) })} required />
              </label>
              <label>
                <span>Heures / jour</span>
                <input type="number" min="0" max="24" value={form.hours_per_day} onChange={(e) => setForm({ ...form, hours_per_day: Number(e.target.value) })} required />
              </label>
              <label className="checkbox-field">
                <input type="checkbox" checked={form.is_critical} onChange={(e) => setForm({ ...form, is_critical: e.target.checked })} />
                <span>Charge critique</span>
              </label>
              <label className="form-grid__full">
                <span>Notes</span>
                <textarea rows={3} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />
              </label>
              <div className="form-grid__full simple-form-section">
                <h4>Position et encombrement sur le site</h4>
                <p className="field-help">
                  L'origine X=0, Y=0 correspond au coin supérieur gauche de la zone d'implantation.
                  Les dimensions représentent la zone occupée par toute cette ligne d'équipement.
                </p>
                <div className="form-grid">
                  <label>
                    <span>Position X (m)</span>
                    <input type="number" min="0" step="0.1" value={form.position_x_m} onChange={(e) => setForm({ ...form, position_x_m: Number(e.target.value) })} />
                  </label>
                  <label>
                    <span>Position Y (m)</span>
                    <input type="number" min="0" step="0.1" value={form.position_y_m} onChange={(e) => setForm({ ...form, position_y_m: Number(e.target.value) })} />
                  </label>
                  <label>
                    <span>Longueur occupée (m)</span>
                    <input type="number" min="0" step="0.1" value={form.footprint_length_m} onChange={(e) => setForm({ ...form, footprint_length_m: Number(e.target.value) })} />
                  </label>
                  <label>
                    <span>Largeur occupée (m)</span>
                    <input type="number" min="0" step="0.1" value={form.footprint_width_m} onChange={(e) => setForm({ ...form, footprint_width_m: Number(e.target.value) })} />
                  </label>
                </div>
              </div>
              <div className="form-actions form-grid__full">
                <button className="button-link button-link--solid" type="submit" disabled={submitting}>
                  {submitting ? 'Ajout...' : 'Ajouter'}
                </button>
                {message ? <p className="form-message">{message}</p> : null}
              </div>
            </form>
            </>
          ) : (
            <p>Votre role ne permet pas de modifier les charges de ce site.</p>
          )}
        </section>
      </div>

      <section className="panel">
        <div className="table-panel__header">
          <div>
            <h3>Plan d'implantation sans chevauchement</h3>
            <p className="panel-message">
              {placedEquipment.length} équipement(s) placé(s) · {occupiedArea.toFixed(2)} m2 occupés
            </p>
          </div>
          <Link className="button-link button-link--ghost button-link--small" to="/sites">
            Modifier les dimensions du site
          </Link>
        </div>
        {layoutLength > 0 && layoutWidth > 0 ? (
          <>
            <div
              className="site-layout"
              style={{ aspectRatio: `${layoutWidth} / ${layoutLength}` }}
              aria-label={`Plan du site de ${layoutWidth} mètres par ${layoutLength} mètres`}
            >
              {placedEquipment.map((item, index) => (
                <div
                  className="site-layout__equipment"
                  key={item.id}
                  title={`${item.name} — X ${item.position_x_m} m, Y ${item.position_y_m} m`}
                  style={{
                    left: `${(item.position_x_m / layoutWidth) * 100}%`,
                    top: `${(item.position_y_m / layoutLength) * 100}%`,
                    width: `${(item.footprint_width_m / layoutWidth) * 100}%`,
                    height: `${(item.footprint_length_m / layoutLength) * 100}%`,
                    background: `hsl(${(index * 67 + 18) % 360} 58% 48% / 0.82)`,
                  }}
                >
                  <span>{item.name}</span>
                </div>
              ))}
            </div>
            {equipment.length > placedEquipment.length ? (
              <p className="form-message">
                {equipment.length - placedEquipment.length} équipement(s) sans dimensions ne figurent pas encore sur le plan.
              </p>
            ) : (
              <p className="form-message">Tous les équipements dimensionnés sont placés sans chevauchement.</p>
            )}
          </>
        ) : (
          <p className="form-message">
            Renseignez d'abord la longueur et la largeur de la zone d'implantation dans « Modifier le site ».
          </p>
        )}
      </section>

      <section className="table-panel">
        <div className="table-panel__header">
          <h3>Charges a alimenter</h3>
          {error ? <p className="form-error">API indisponible ou equipements non charges.</p> : null}
          {message ? <p className="form-message">{message}</p> : null}
        </div>
        <table className="data-table">
          <thead>
            <tr>
              <th>Equipement</th>
              <th>Categorie</th>
              <th>Puissance</th>
              <th>Quantite</th>
              <th>Heures/jour</th>
              <th>Critique</th>
              <th>Position X / Y</th>
              <th>Encombrement L × l</th>
              {canEdit ? <th>Actions</th> : null}
            </tr>
          </thead>
          <tbody>
            {equipment.map((item) => (
              <tr key={item.id}>
                <td>
                  {editingEquipmentId === item.id ? (
                    <input
                      value={editingForm.name}
                      onChange={(e) => setEditingForm({ ...editingForm, name: e.target.value })}
                    />
                  ) : (
                    item.name
                  )}
                </td>
                <td>
                  {editingEquipmentId === item.id ? (
                    <input
                      value={editingForm.category}
                      onChange={(e) => setEditingForm({ ...editingForm, category: e.target.value })}
                    />
                  ) : (
                    item.category
                  )}
                </td>
                <td>
                  {editingEquipmentId === item.id ? (
                    <input
                      type="number"
                      min="1"
                      value={editingForm.power_watts}
                      onChange={(e) =>
                        setEditingForm({ ...editingForm, power_watts: Number(e.target.value) })
                      }
                    />
                  ) : (
                    `${item.power_watts} W`
                  )}
                </td>
                <td>
                  {editingEquipmentId === item.id ? (
                    <input
                      type="number"
                      min="1"
                      value={editingForm.quantity}
                      onChange={(e) =>
                        setEditingForm({ ...editingForm, quantity: Number(e.target.value) })
                      }
                    />
                  ) : (
                    item.quantity
                  )}
                </td>
                <td>
                  {editingEquipmentId === item.id ? (
                    <input
                      type="number"
                      min="0"
                      max="24"
                      value={editingForm.hours_per_day}
                      onChange={(e) =>
                        setEditingForm({ ...editingForm, hours_per_day: Number(e.target.value) })
                      }
                    />
                  ) : (
                    item.hours_per_day
                  )}
                </td>
                <td>
                  {editingEquipmentId === item.id ? (
                    <label className="checkbox-field">
                      <input
                        type="checkbox"
                        checked={editingForm.is_critical}
                        onChange={(e) =>
                          setEditingForm({ ...editingForm, is_critical: e.target.checked })
                        }
                      />
                      <span>{editingForm.is_critical ? 'Oui' : 'Non'}</span>
                    </label>
                  ) : item.is_critical ? (
                    'Oui'
                  ) : (
                    'Non'
                  )}
                </td>
                <td>
                  {editingEquipmentId === item.id ? (
                    <div className="compact-inputs">
                      <input type="number" min="0" step="0.1" aria-label="Position X" value={editingForm.position_x_m} onChange={(e) => setEditingForm({ ...editingForm, position_x_m: Number(e.target.value) })} />
                      <input type="number" min="0" step="0.1" aria-label="Position Y" value={editingForm.position_y_m} onChange={(e) => setEditingForm({ ...editingForm, position_y_m: Number(e.target.value) })} />
                    </div>
                  ) : (
                    `${item.position_x_m ?? 0} / ${item.position_y_m ?? 0} m`
                  )}
                </td>
                <td>
                  {editingEquipmentId === item.id ? (
                    <div className="compact-inputs">
                      <input type="number" min="0" step="0.1" aria-label="Longueur occupée" value={editingForm.footprint_length_m} onChange={(e) => setEditingForm({ ...editingForm, footprint_length_m: Number(e.target.value) })} />
                      <input type="number" min="0" step="0.1" aria-label="Largeur occupée" value={editingForm.footprint_width_m} onChange={(e) => setEditingForm({ ...editingForm, footprint_width_m: Number(e.target.value) })} />
                    </div>
                  ) : item.footprint_length_m > 0 && item.footprint_width_m > 0 ? (
                    `${item.footprint_length_m} × ${item.footprint_width_m} m`
                  ) : (
                    'Non renseigné'
                  )}
                </td>
                {canEdit ? (
                  <td>
                    <div className="form-actions">
                      {editingEquipmentId === item.id ? (
                        <>
                          <button
                            className="button-link button-link--solid"
                            type="button"
                            onClick={() => handleUpdateEquipment(item.id)}
                            disabled={actionEquipmentId === item.id}
                          >
                            {actionEquipmentId === item.id ? 'Sauvegarde...' : 'Enregistrer'}
                          </button>
                          <button
                            className="button-link button-link--ghost"
                            type="button"
                            onClick={cancelEditing}
                            disabled={actionEquipmentId === item.id}
                          >
                            Annuler
                          </button>
                        </>
                      ) : (
                        <>
                          <button
                            className="button-link button-link--ghost"
                            type="button"
                            onClick={() => startEditing(item)}
                            disabled={actionEquipmentId === item.id}
                          >
                            Modifier
                          </button>
                          <button
                            className="button-link button-link--ghost"
                            type="button"
                            onClick={() => handleDeleteEquipment(item.id)}
                            disabled={actionEquipmentId === item.id}
                          >
                            {actionEquipmentId === item.id ? 'Suppression...' : 'Supprimer'}
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                ) : null}
              </tr>
            ))}
            {equipment.length === 0 ? (
              <tr>
                <td colSpan={canEdit ? 9 : 8}>Aucun equipement enregistre pour ce site.</td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </section>
    </section>
  )
}
