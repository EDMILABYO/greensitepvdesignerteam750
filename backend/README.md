# GreenSite PV Simulator API

API FastAPI pour simuler le dimensionnement photovoltaique d'un site telecom avec des donnees exclusivement academiques.

## Installation

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload
```

## Endpoints principaux

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `POST /sites`
- `GET /sites`
- `POST /sites/{site_id}/equipment`
- `POST /simulations`
- `POST /simulations/{simulation_id}/calculate`
- `GET /simulations/{simulation_id}/report`

Documentation interactive : `/docs`.

## Donnees de test

```powershell
python -m app.seed
```

Compte cree : `student@example.com / password123`.

## PostgreSQL Render

Configurer :

```env
DATABASE_URL=postgresql://username:password@host:port/database
SECRET_KEY=replace_with_a_long_random_secret
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
ENVIRONMENT=production
```

Le fichier `render.yaml` peut etre utilise pour creer le web service et la base PostgreSQL.
