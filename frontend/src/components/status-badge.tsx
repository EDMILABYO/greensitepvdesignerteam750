import type { FeasibilityStatus } from '../types/domain'

const labels: Record<FeasibilityStatus, string> = {
  FAISABLE: 'Faisable',
  FAISABLE_AVEC_DELESTAGE: 'Faisable avec delestage',
  NON_FAISABLE_PAR_SURFACE: 'Non faisable par surface',
  NON_FAISABLE_PAR_AUTONOMIE: 'Non faisable par autonomie',
  NON_FAISABLE_PAR_CAPACITE: 'Non faisable par capacite',
}

export function StatusBadge({ status }: { status: FeasibilityStatus }) {
  return <span className={`status-badge status-${status.toLowerCase()}`}>{labels[status]}</span>
}
