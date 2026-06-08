# GreenSite PV Simulator

Application academique de simulation et de dimensionnement photovoltaique pour un site de telecommunication Green Site. Les donnees HAYATCOM/GOMA incluses sont fictives et servent uniquement de scenario de demonstration.

## Contenu

- `lib/` : application mobile Flutter Android-first.
- `backend/` : API FastAPI avec SQLModel, JWT, migrations Alembic et configuration Render.
- `backend/app/seed.py` : jeu de donnees simule `student@example.com / password123`.

## Backend local

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --reload
```

Swagger est disponible sur `http://localhost:8000/docs`.

Pour creer les donnees de test :

```powershell
cd backend
python -m app.seed
```

En developpement, l'API utilise SQLite si `DATABASE_URL` n'est pas defini. Pour PostgreSQL Render, renseigner `DATABASE_URL`, `SECRET_KEY`, `ALGORITHM` et `ACCESS_TOKEN_EXPIRE_MINUTES`.

## Migrations

```powershell
cd backend
alembic upgrade head
```

## Deploiement Render

Le fichier `backend/render.yaml` declare un service web FastAPI et une base PostgreSQL. Sur Render, creer le Blueprint depuis le dossier `backend`, puis verifier que `DATABASE_URL` et `SECRET_KEY` sont bien fournis.

## Application Flutter

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Sur un appareil physique, remplacer `10.0.2.2` par l'adresse IP locale de la machine qui execute FastAPI.

L'application contient un mode demo local: si l'API n'est pas joignable au moment de la connexion, elle permet quand meme de presenter les ecrans, les calculs, l'historique et le rapport.

## Formules implementees

- Puissance totale : somme `puissance x quantite`.
- Energie journaliere : somme `puissance x quantite x heures/jour`.
- Energie corrigee : `energie journaliere / rendement`.
- Puissance PV : `energie corrigee / heures solaires`.
- Batteries : `energie journaliere x autonomie / tension / DOD`.
- Regulateur : `puissance PV / tension x 1.25`.
- Onduleur : `puissance totale x 1.25`.
- Cout total : panneaux + batteries + regulateur + onduleur + accessoires + main d'oeuvre + maintenance.

## Phase 1 - Faisabilite

Le module Audit calcule maintenant :

- profil de charge journalier et energie annuelle ;
- consommation diesel annuelle estimee ;
- OPEX diesel annuel ;
- TCO diesel vs TCO solaire sur 20 ans ;
- retour sur investissement ;
- CO2 evite ;
- score et verdict de faisabilite.

## Phase 2 - Conception et Dimensionnement

Le module Conception PV inclut maintenant :

- choix technologie panneau : monocristallin, polycristallin, bifacial ;
- choix technologie batterie : LiFePO4, plomb-carbone, plomb-acide ;
- choix regulateur MPPT ou PWM ;
- rendement MPPT et rendement onduleur ;
- pertes cables, temperature et poussiere ;
- facteur de securite configurable ;
- architecture recommandee ;
- protections DC/AC recommandees ;
- resultats de dimensionnement panneaux, batteries, regulateur et onduleur.

## Phase 3 - Implementation et Optimisation

Le module Implementation couvre :

- orientation recommandee selon la latitude ;
- inclinaison recommandee des panneaux ;
- checklist installation terrain ;
- protocole de tests post-installation ;
- comparaison production theorique vs production mesuree ;
- performance ratio ;
- controle tension batterie ;
- optimisation des charges par veille intelligente ;
- alertes operationnelles ;
- recommandations de supervision distante.

## Phase 4 - Suivi, Maintenance et Valorisation

Le module Suivi maintenance couvre :

- KPI de disponibilite, performance ratio, SOC, SOH et cycles batterie ;
- evaluation de sante globale du site ;
- planning de nettoyage panneaux ;
- planning d'inspection electrique ;
- alertes automatiques ;
- bilan CO2 evite ;
- potentiel de generalisation multi-sites ;
- points de valorisation RSE et rapport mensuel.
