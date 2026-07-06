# HAYAT-Solar Sizer — Frontend

Interface React/Vite de l'application de dimensionnement photovoltaïque.

## Développement local

```powershell
npm install
npm run dev
```

Sans configuration supplémentaire, le frontend local utilise :

```text
http://localhost:8000
```

## Déploiement Vercel

Le dossier racine du projet Vercel doit être `frontend`.

Configurer cette variable pour les environnements Production et Preview :

```text
VITE_API_BASE_URL=https://greensitepvdesignerteam750.onrender.com
```

Après toute modification de cette variable, déclencher un nouveau déploiement : les variables
Vite sont intégrées au bundle pendant la compilation.

En production, l'URL Render ci-dessus est également utilisée comme valeur de secours lorsque la
variable est absente. Le fichier `vercel.json` redirige les routes React comme `/login` vers
`index.html`.

## Déploiement Render et Supabase

Dans Render, définir `DATABASE_URL` avec la chaîne de connexion Supabase. Cette valeur reste
secrète et ne doit pas être ajoutée au dépôt. Le fichier `backend/render.yaml` attend cette
variable comme valeur externe.
