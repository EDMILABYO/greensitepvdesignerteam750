from sqlmodel import Session, select

from app.database import create_db_and_tables, engine
from app.models.client import Client
from app.models.equipment import Equipment
from app.models.simulation import Simulation
from app.models.site import Site
from app.models.user import User, UserRole
from app.services.calculation_service import calculate_simulation
from app.utils.security import hash_password


def run() -> None:
    create_db_and_tables()
    with Session(engine) as session:
        existing = session.exec(
            select(User).where(User.email == "student@example.com")
        ).first()
        if existing:
            user = existing
        else:
            user = User(
                full_name="Etudiant Demo",
                email="student@example.com",
                hashed_password=hash_password("password123"),
                role=UserRole.student,
            )
            session.add(user)
            session.commit()
            session.refresh(user)

        existing_client = session.exec(
            select(Client).where(
                Client.user_id == (user.id or 0),
                Client.email == "client@example.com",
            )
        ).first()
        if not existing_client:
            client = Client(
                user_id=user.id or 0,
                name="Client academique",
                organization="Green Site Demo",
                phone="+243 000 000 000",
                email="client@example.com",
                address="Goma, RDC",
                notes="Client fictif pour presentation academique.",
            )
            session.add(client)
            session.commit()

        existing_site = session.exec(
            select(Site).where(
                Site.user_id == (user.id or 0),
                Site.name == "HAYATCOM/GOMA Simulation",
            )
        ).first()
        if existing_site:
            print("Seed data already exists.")
            return

        site = Site(
            user_id=user.id or 0,
            name="HAYATCOM/GOMA Simulation",
            city="Goma",
            country="RDC",
            site_type="Site BTS simule",
            description="Profil academique simule pour dimensionnement PV telecom.",
            operating_hours_per_day=24,
            autonomy_days=2,
            solar_irradiation_hours=5,
            system_efficiency=0.8,
            system_voltage=48,
        )
        session.add(site)
        session.commit()
        session.refresh(site)

        equipment_rows = [
            ("BTS", "BTS / antenne", 800, 1, 24),
            ("Routeur", "Routeur", 150, 1, 24),
            ("Switch", "Switch", 100, 1, 24),
            ("Faisceau hertzien", "Faisceau hertzien", 200, 1, 24),
            ("Ventilation", "Ventilation", 300, 1, 12),
            ("Eclairage", "Eclairage", 50, 4, 10),
        ]
        equipment = [
            Equipment(
                site_id=site.id or 0,
                name=name,
                category=category,
                power_watts=power,
                quantity=quantity,
                hours_per_day=hours,
            )
            for name, category, power, quantity, hours in equipment_rows
        ]
        session.add_all(equipment)

        simulation = Simulation(
            user_id=user.id or 0,
            site_id=site.id or 0,
            panel_power_watts=550,
            battery_capacity_ah=200,
            battery_voltage=12,
            battery_dod=0.8,
            panel_unit_price=150,
            battery_unit_price=250,
            inverter_price=500,
            controller_price=300,
            accessories_price=400,
            labor_price=500,
        )
        session.add(simulation)
        session.commit()
        session.refresh(simulation)
        result = calculate_simulation(site, equipment, simulation)
        result.simulation_id = simulation.id or 0
        session.add(result)
        session.commit()
        print("Seed data created: student@example.com / password123")


if __name__ == "__main__":
    run()
