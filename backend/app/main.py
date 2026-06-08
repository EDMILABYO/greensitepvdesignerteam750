from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import create_db_and_tables
from app.routes import (
    auth_routes,
    client_routes,
    design_routes,
    equipment_routes,
    feasibility_routes,
    simulation_routes,
    site_routes,
)

app = FastAPI(
    title="GreenSite PV Simulator API",
    description=(
        "API academique pour simuler et dimensionner un systeme photovoltaique "
        "d'un site telecom avec des donnees strictement simulees."
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_routes.router)
app.include_router(client_routes.router)
app.include_router(design_routes.router)
app.include_router(feasibility_routes.router)
app.include_router(site_routes.router)
app.include_router(equipment_routes.router)
app.include_router(simulation_routes.router)


@app.on_event("startup")
def on_startup() -> None:
    create_db_and_tables()


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "GreenSite PV Simulator",
        "notice": (
            "Les donnees utilisees dans cette application sont simulees et "
            "destinees uniquement a un usage academique."
        ),
        "docs": "/docs",
    }
