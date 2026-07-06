import argparse
from getpass import getpass

from sqlmodel import Session, select

from app.database import engine
from app.models.user import User
from app.utils.security import hash_password


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Reinitialise le mot de passe d'un utilisateur sans l'afficher."
    )
    parser.add_argument("--email", required=True, help="Adresse email du compte")
    args = parser.parse_args()
    email = args.email.strip().lower()

    password = getpass("Nouveau mot de passe : ")
    confirmation = getpass("Confirmer le mot de passe : ")

    if len(password) < 8:
        raise SystemExit("Le mot de passe doit contenir au moins 8 caracteres.")
    if password != confirmation:
        raise SystemExit("Les mots de passe ne correspondent pas.")

    with Session(engine) as session:
        user = session.exec(select(User).where(User.email == email)).first()
        if not user:
            raise SystemExit(f"Aucun utilisateur trouve pour {email}.")

        user.hashed_password = hash_password(password)
        session.add(user)
        session.commit()

    print(f"Mot de passe reinitialise pour {email}.")


if __name__ == "__main__":
    main()
