# Cahier De Conception - GreenSite PV Designer Web

## 1. Contexte

L'application a pour objectif de dimensionner un systeme photovoltaique de back-up pour un site de telecommunication de type Green Site, avec comme cas principal HAYATCOM/Goma. L'outil doit devenir une application web exploitable et non plus une simple demonstration academique.

L'application doit tenir compte des contraintes suivantes :

- les contraintes reelles de calcul
- l'espace reellement disponible
- la surface reelle occupee par les panneaux
- le temps de fonctionnement en cas de coupure du courant et de defaillance du groupe electrogene
- l'etat de sortie genere par le dimensionnement automatique

## 2. Objectif General

Concevoir une application web permettant :

- d'enregistrer un site telecom
- de decrire ses charges critiques et non critiques
- de saisir les contraintes terrain
- de lancer un dimensionnement automatique
- d'afficher un verdict technique de faisabilite
- de produire une sortie lisible et exploitable sous forme de rapport

## 3. Stack Technique

- Frontend : React.js + TypeScript
- Backend : FastAPI existant, a ameliorer
- Base de donnees : Supabase Postgres
- Authentification : JWT FastAPI dans un premier temps
- Deploiement frontend : Vercel ou Netlify
- Deploiement backend : Render

## 4. Roles Utilisateurs

### 4.1 Administrateur

- gere les utilisateurs
- consulte toutes les simulations
- valide les donnees et rapports

### 4.2 Ingenieur Energie

- cree un site
- saisit les parametres energetiques
- lance les calculs
- interprete les resultats

### 4.3 Technicien Maintenance

- consulte l'etat de sortie
- accede aux recommandations
- prepare les interventions terrain

### 4.4 Superviseur

- consulte le tableau de bord
- compare les simulations
- exporte les rapports

## 5. Modules Fonctionnels

### 5.1 Authentification

- connexion utilisateur
- recuperation du profil
- gestion des roles

### 5.2 Gestion Des Sites

- creation d'un site
- edition des informations du site
- saisie de la localisation
- saisie de la surface disponible
- saisie des contraintes d'installation

### 5.3 Audit Energetique

- ajout des equipements
- classification charge critique / non critique
- puissance, quantite, duree d'utilisation
- estimation de l'energie journaliere

### 5.4 Dimensionnement Automatique

- calcul de la puissance PV
- calcul de la capacite batterie
- calcul de l'autonomie
- verification de la surface utile
- prise en compte de la panne groupe
- prise en compte des pertes
- etat de sortie final

### 5.5 Resultats Et Rapports

- synthese de dimensionnement
- verdict faisable / non faisable
- alertes techniques
- recommandations
- export PDF et JSON

### 5.6 Tableau De Bord

- simulations recentes
- moyenne des dimensionnements
- statuts des projets
- comparatif des scenarios

## 6. Contraintes Metier Obligatoires

Le moteur de calcul doit obligatoirement integrer :

- la charge totale critique
- la charge totale non critique
- l'energie journaliere
- le rendement global du systeme
- les pertes dues au regulateur, a l'onduleur, aux cables, a la temperature et a la poussiere
- le temps d'autonomie exige
- la tension systeme
- la profondeur de decharge batterie
- la surface unitaire des panneaux
- un coefficient d'espacement et de maintenance
- la surface reellement disponible sur le site
- le scenario de panne du groupe electrogene

## 7. Donnees D'Entree

### 7.1 Site

- nom du site
- ville
- pays
- type de site
- description
- latitude
- longitude
- tension du systeme
- heures solaires
- rendement systeme
- surface disponible en m2
- ratio de surface exploitable
- autonomie cible en heures
- groupe electrogene disponible ou non
- calcul en cas de defaillance du groupe

### 7.2 Equipements

- nom
- categorie
- charge critique ou non critique
- puissance en watts
- quantite
- heures par jour

### 7.3 Parametres De Simulation

- puissance unitaire du panneau
- longueur et largeur du panneau
- surface unitaire du panneau
- type de panneau
- type de batterie
- tension batterie
- capacite batterie en Ah
- energie batterie en kWh
- DoD batterie
- rendement onduleur
- rendement regulateur
- pertes cables
- pertes temperature
- pertes poussiere
- facteur de securite
- couts unitaires

## 8. Sortie Attendue Du Dimensionnement

L'application doit produire une sortie technique lisible comprenant :

- puissance totale installee
- puissance critique
- puissance non critique
- energie journaliere
- energie corrigee
- puissance PV requise
- nombre de panneaux
- surface minimale des panneaux
- surface reelle avec espacement
- surface disponible du site
- statut de compatibilite de surface
- capacite batterie utile
- capacite batterie nominale
- nombre de batteries
- courant regulateur
- puissance onduleur recommandee
- temps de fonctionnement estime
- statut en cas de coupure reseau + panne groupe
- necessite de delestage ou non
- niveau de faisabilite
- recommandations techniques
- cout total estime

## 9. Verdicts Metier

Chaque simulation doit aboutir a un etat de sortie :

- `FAISABLE`
- `FAISABLE_AVEC_DELESTAGE`
- `NON_FAISABLE_PAR_SURFACE`
- `NON_FAISABLE_PAR_AUTONOMIE`
- `NON_FAISABLE_PAR_CAPACITE`

## 10. Pages Frontend React

- `/login`
- `/dashboard`
- `/sites`
- `/sites/new`
- `/sites/:id`
- `/sites/:id/equipment`
- `/sites/:id/simulation/new`
- `/simulations`
- `/simulations/:id`
- `/simulations/:id/report`

## 11. Composants Frontend Principaux

- layout principal
- sidebar de navigation
- formulaire site
- tableau des equipements
- formulaire simulation
- carte de resultat
- tableau de sortie technique
- badge de faisabilite
- bloc alertes et recommandations
- comparateur de scenarios

## 12. API Cible

### 12.1 Sites

- `POST /sites`
- `GET /sites`
- `GET /sites/{id}`
- `PUT /sites/{id}`

### 12.2 Equipements

- `POST /sites/{site_id}/equipment`
- `GET /sites/{site_id}/equipment`
- `PUT /equipment/{id}`
- `DELETE /equipment/{id}`

### 12.3 Simulations

- `POST /simulations`
- `GET /simulations`
- `GET /simulations/{id}`
- `POST /simulations/{id}/calculate`
- `GET /simulations/{id}/report`

### 12.4 Dashboard

- `GET /simulations/dashboard/summary`

## 13. Evolution De La Base De Donnees

### 13.1 Table `sites`

Nouveaux champs a ajouter :

- `latitude`
- `longitude`
- `available_area_m2`
- `usable_area_ratio`
- `target_backup_hours`
- `generator_available`
- `generator_failure_scenario`

### 13.2 Table `equipment`

Nouveaux champs a ajouter :

- `is_critical`
- `notes`

### 13.3 Table `simulations`

Nouveaux champs a ajouter :

- `panel_type`
- `panel_length_m`
- `panel_width_m`
- `panel_area_m2`
- `panel_spacing_factor`
- `battery_type`
- `battery_energy_kwh`
- `controller_efficiency`
- `inverter_efficiency`
- `cable_loss_factor`
- `temperature_loss_factor`
- `dust_loss_factor`
- `safety_factor`

### 13.4 Table `simulation_results`

Nouveaux champs a ajouter :

- `critical_power_watts`
- `non_critical_power_watts`
- `critical_energy_wh`
- `non_critical_energy_wh`
- `backup_time_hours`
- `panel_surface_required_m2`
- `panel_surface_with_spacing_m2`
- `available_surface_m2`
- `surface_status`
- `feasibility_status`
- `dimensioning_state`
- `load_shedding_required`
- `load_shedding_message`
- `warnings_json`
- `recommended_configuration_json`

## 14. Ordre D'Implementation

### Etape 1

Formaliser le cahier de conception et le modele metier cible.

### Etape 2

Etendre les modeles SQLModel, schemas Pydantic et migrations Alembic.

### Etape 3

Refondre le moteur de calcul pour integrer les contraintes reelles.

### Etape 4

Adapter les routes de simulation et les rapports.

### Etape 5

Creer le frontend React et les routes de navigation.

### Etape 6

Construire les formulaires de saisie.

### Etape 7

Afficher la sortie detaillee du dimensionnement automatique.

### Etape 8

Brancher Supabase Postgres et preparer le deploiement.

## 15. Critere De Reussite

L'application sera consideree comme correctement implemente si :

- les contraintes reelles sont presentes dans les donnees d'entree
- le calcul integre la surface disponible et la panne du groupe
- la sortie affiche un etat de faisabilite clair
- le rapport est comprensible par un encadreur ou un technicien
- le frontend React est connecte proprement au backend FastAPI
- la base Supabase stocke les sites, les equipements, les simulations et les resultats
