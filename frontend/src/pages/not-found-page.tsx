import { Link } from 'react-router-dom'

export function NotFoundPage() {
  return (
    <section className="page page--centered">
      <div className="panel panel--compact">
        <span className="section-title__eyebrow">404</span>
        <h2>Page introuvable</h2>
        <p>La route demandee n&apos;existe pas encore dans l&apos;application web.</p>
        <Link className="button-link" to="/">
          Retour au dashboard
        </Link>
      </div>
    </section>
  )
}
