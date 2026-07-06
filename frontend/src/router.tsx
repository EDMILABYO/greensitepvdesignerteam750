import { createBrowserRouter } from 'react-router-dom'
import { AuthGuard } from './components/auth-guard'
import { AppShell } from './layouts/app-shell'
import { DashboardPage } from './pages/dashboard-page'
import { LoginPage } from './pages/login-page'
import { NewSimulationPage } from './pages/new-simulation-page'
import { NotFoundPage } from './pages/not-found-page'
import { ReportDetailPage } from './pages/report-detail-page'
import { ReportsPage } from './pages/reports-page'
import { SimulationDetailPage } from './pages/simulation-detail-page'
import { SimulationsPage } from './pages/simulations-page'
import { SiteDetailPage } from './pages/site-detail-page'
import { SitesPage } from './pages/sites-page'
import { UsersPage } from './pages/users-page'

export const router = createBrowserRouter([
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    element: <AuthGuard />,
    children: [
      {
        path: '/',
        element: <AppShell />,
        errorElement: <NotFoundPage />,
        children: [
          { index: true, element: <DashboardPage /> },
          { path: 'sites', element: <SitesPage /> },
          { path: 'sites/:siteId', element: <SiteDetailPage /> },
          { path: 'simulations', element: <SimulationsPage /> },
          { path: 'simulations/new', element: <NewSimulationPage /> },
          { path: 'simulations/:simulationId/edit', element: <NewSimulationPage /> },
          { path: 'simulations/:simulationId', element: <SimulationDetailPage /> },
          { path: 'simulations/:simulationId/report', element: <ReportDetailPage /> },
          { path: 'reports', element: <ReportsPage /> },
          { path: 'users', element: <UsersPage /> },
        ],
      },
    ],
  },
])
