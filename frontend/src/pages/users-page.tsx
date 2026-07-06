import { useMemo, useState } from 'react'
import { SectionTitle } from '../components/section-title'
import { useAuth } from '../hooks/use-auth'
import { useProtectedQuery } from '../hooks/use-protected-query'
import {
  createAdminUser,
  deleteAdminUser,
  listAdminUsers,
  updateAdminUser,
} from '../services/admin-service'
import {
  ROLE_OPTIONS,
  type AdminUserPayload,
  type AdminUserUpdatePayload,
  type AuthUser,
  type UserRole,
} from '../types/auth'

const initialForm: AdminUserPayload = {
  full_name: '',
  email: '',
  password: '',
  role: 'student',
}

const initialEditForm: AdminUserUpdatePayload = {
  full_name: '',
  email: '',
  password: '',
  role: 'student',
}

function getRoleLabel(role: UserRole) {
  return ROLE_OPTIONS.find((item) => item.value === role)?.label ?? role
}

export function UsersPage() {
  const { token, user } = useAuth()
  const { data: users, error, loading, setData } = useProtectedQuery({
    fallbackData: [],
    queryKey: 'admin-users',
    request: listAdminUsers,
  })
  const [form, setForm] = useState<AdminUserPayload>(initialForm)
  const [editForm, setEditForm] = useState<AdminUserUpdatePayload>(initialEditForm)
  const [submitting, setSubmitting] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [editingUserId, setEditingUserId] = useState<number | null>(null)
  const [editingUser, setEditingUser] = useState<AuthUser | null>(null)

  const sortedUsers = useMemo(() => users, [users])

  async function handleCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!token) {
      setMessage('Connexion requise.')
      return
    }

    setSubmitting(true)
    setMessage(null)
    try {
      const created = await createAdminUser(token, form)
      setData([created, ...users])
      setForm(initialForm)
      setMessage('Utilisateur cree avec succes.')
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Creation impossible.')
    } finally {
      setSubmitting(false)
    }
  }

  function openEditModal(targetUser: AuthUser) {
    setEditingUser(targetUser)
    setEditForm({
      full_name: targetUser.full_name,
      email: targetUser.email,
      password: '',
      role: targetUser.role,
    })
    setMessage(null)
  }

  function closeEditModal() {
    if (editingUserId !== null) return
    setEditingUser(null)
    setEditForm(initialEditForm)
  }

  async function handleEditSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!token || !editingUser) return

    const payload: AdminUserUpdatePayload = {
      full_name: editForm.full_name?.trim(),
      email: editForm.email?.trim(),
      role: editForm.role,
      ...(editForm.password ? { password: editForm.password } : {}),
    }

    if (!payload.full_name || !payload.email || !payload.role) {
      setMessage('Completer toutes les informations obligatoires.')
      return
    }

    setEditingUserId(editingUser.id)
    setMessage(null)
    try {
      const updated = await updateAdminUser(token, editingUser.id, payload)
      setData(users.map((item) => (item.id === updated.id ? updated : item)))
      setMessage('Utilisateur mis a jour.')
      setEditingUser(null)
      setEditForm(initialEditForm)
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Mise a jour impossible.')
    } finally {
      setEditingUserId(null)
    }
  }

  async function handleDelete(targetUser: AuthUser) {
    if (!token) return
    const confirmed = window.confirm(`Supprimer ${targetUser.full_name} ?`)
    if (!confirmed) return

    setEditingUserId(targetUser.id)
    setMessage(null)
    try {
      await deleteAdminUser(token, targetUser.id)
      setData(users.filter((item) => item.id !== targetUser.id))
      setMessage('Utilisateur supprime.')
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Suppression impossible.')
    } finally {
      setEditingUserId(null)
    }
  }

  if (user?.role !== 'admin') {
    return (
      <section className="page">
        <div className="panel">
          <h3>Acces refuse</h3>
          <p>Cette section est reservee a l administrateur.</p>
        </div>
      </section>
    )
  }

  return (
    <section className="page">
      <SectionTitle
        eyebrow="Administration"
        title="Gestion des utilisateurs"
        text="Creer, mettre a jour les roles, reinitialiser les mots de passe et supprimer les comptes."
      />

      <div className="page-grid">
        <section className="panel">
          <h3>Nouvel utilisateur</h3>
          <form className="form-grid" onSubmit={handleCreate}>
            <label>
              <span>Nom complet</span>
              <input
                value={form.full_name}
                onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                required
              />
            </label>
            <label>
              <span>Email</span>
              <input
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                required
              />
            </label>
            <label>
              <span>Mot de passe</span>
              <input
                type="password"
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                required
              />
            </label>
            <label>
              <span>Role</span>
              <select
                value={form.role}
                onChange={(e) => setForm({ ...form, role: e.target.value as UserRole })}
              >
                {ROLE_OPTIONS.map((roleOption) => (
                  <option key={roleOption.value} value={roleOption.value}>
                    {roleOption.label}
                  </option>
                ))}
              </select>
            </label>
            <div className="form-actions form-grid__full">
              <button className="button-link button-link--solid" type="submit" disabled={submitting}>
                {submitting ? 'Creation...' : 'Creer'}
              </button>
              {message ? <p className="form-message">{message}</p> : null}
            </div>
          </form>
        </section>

        <section className="panel">
          <h3>Resume</h3>
          <p>{loading ? 'Chargement des utilisateurs...' : `${sortedUsers.length} utilisateur(s) disponible(s).`}</p>
          {error ? <p className="form-error">API indisponible ou acces admin refuse.</p> : null}
        </section>
      </div>

      <section className="table-panel">
        <div className="table-panel__header">
          <h3>Comptes utilisateurs</h3>
        </div>
        <table className="data-table">
          <thead>
            <tr>
              <th>Nom</th>
              <th>Email</th>
              <th>Role</th>
              <th>Creation</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {sortedUsers.map((item) => (
              <tr key={item.id}>
                <td>{item.full_name}</td>
                <td>{item.email}</td>
                <td>
                  <span className={`role-badge role-badge--${item.role}`}>
                    {getRoleLabel(item.role)}
                  </span>
                </td>
                <td>{new Date(item.created_at).toLocaleDateString()}</td>
                <td>
                  <div className="table-actions">
                    <button
                      className="button-link button-link--ghost button-link--small"
                      type="button"
                      onClick={() => openEditModal(item)}
                      disabled={editingUserId === item.id}
                    >
                      Modifier
                    </button>
                    {user?.id !== item.id ? (
                      <button
                        className="button-link button-link--danger button-link--small"
                        type="button"
                        onClick={() => handleDelete(item)}
                        disabled={editingUserId === item.id}
                      >
                        Supprimer
                      </button>
                    ) : null}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      {editingUser ? (
        <div className="modal-backdrop" role="presentation" onClick={closeEditModal}>
          <div className="modal-card" role="dialog" aria-modal="true" onClick={(event) => event.stopPropagation()}>
            <div className="table-panel__header">
              <h3>Modifier l&apos;utilisateur</h3>
              <button className="button-link button-link--ghost button-link--small" type="button" onClick={closeEditModal}>
                Fermer
              </button>
            </div>

            <form className="form-grid" onSubmit={handleEditSubmit}>
              <label>
                <span>Nom complet</span>
                <input
                  value={editForm.full_name ?? ''}
                  onChange={(e) => setEditForm({ ...editForm, full_name: e.target.value })}
                  required
                />
              </label>
              <label>
                <span>Email</span>
                <input
                  type="email"
                  value={editForm.email ?? ''}
                  onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                  required
                />
              </label>
              <label>
                <span>Role</span>
                <select
                  value={editForm.role ?? 'student'}
                  onChange={(e) => setEditForm({ ...editForm, role: e.target.value as UserRole })}
                >
                  {ROLE_OPTIONS.map((roleOption) => (
                    <option key={roleOption.value} value={roleOption.value}>
                      {roleOption.label}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                <span>Nouveau mot de passe</span>
                <input
                  type="password"
                  value={editForm.password ?? ''}
                  onChange={(e) => setEditForm({ ...editForm, password: e.target.value })}
                  placeholder="Laisser vide si inchange"
                />
              </label>
              <div className="form-actions form-grid__full">
                <button className="button-link button-link--solid" type="submit" disabled={editingUserId === editingUser.id}>
                  {editingUserId === editingUser.id ? 'Mise a jour...' : 'Enregistrer'}
                </button>
                <button className="button-link button-link--ghost" type="button" onClick={closeEditModal} disabled={editingUserId === editingUser.id}>
                  Annuler
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </section>
  )
}
