"""Point d'entree ASGI de l'API.

Depuis le dossier backend :
    python -m uvicorn main:app --reload
"""

from app.main import app


__all__ = ["app"]
