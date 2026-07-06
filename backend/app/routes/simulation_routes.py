from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlmodel import Session, select

from app.database import get_session
from app.models.equipment import Equipment
from app.models.result import SimulationResult
from app.models.simulation import Simulation
from app.models.site import Site
from app.models.user import User
from app.schemas.simulation_schema import (
    ReportRead,
    SimulationCreate,
    SimulationDetail,
    SimulationRead,
    SimulationResultRead,
    SimulationUpdate,
)
from app.services.auth_service import (
    can_view_all_records,
    get_current_user,
    require_simulation_permission,
)
from app.services.calculation_service import calculate_simulation
from app.services.report_service import build_report_payload, generate_report_pdf

router = APIRouter(prefix="/simulations", tags=["Simulations"])

ACADEMIC_NOTICE = (
    "Les donnees utilisees dans cette application sont simulees et destinees "
    "uniquement a un usage academique."
)


def _site_for_user(site_id: int, user: User, session: Session) -> Site:
    site = session.get(Site, site_id)
    if not site or (site.user_id != user.id and not can_view_all_records(user)):
        raise HTTPException(status_code=404, detail="Site not found")
    return site


def _simulation_for_user(simulation_id: int, user: User, session: Session) -> Simulation:
    simulation = session.get(Simulation, simulation_id)
    if not simulation or (simulation.user_id != user.id and not can_view_all_records(user)):
        raise HTTPException(status_code=404, detail="Simulation not found")
    return simulation


def _result_for_simulation(session: Session, simulation_id: int) -> SimulationResult | None:
    return session.exec(
        select(SimulationResult).where(SimulationResult.simulation_id == simulation_id)
    ).first()


@router.post("", response_model=SimulationRead, status_code=status.HTTP_201_CREATED)
def create_simulation(
    payload: SimulationCreate,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Simulation:
    require_simulation_permission(user)
    _site_for_user(payload.site_id, user, session)
    simulation = Simulation(**payload.model_dump(), user_id=user.id)
    session.add(simulation)
    session.commit()
    session.refresh(simulation)
    return simulation


@router.get("", response_model=list[SimulationDetail])
def list_simulations(
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> list[SimulationDetail]:
    statement = select(Simulation)
    if not can_view_all_records(user):
        statement = statement.where(Simulation.user_id == user.id)
    simulations = session.exec(statement.order_by(Simulation.created_at.desc())).all()
    details: list[SimulationDetail] = []
    for simulation in simulations:
        data = SimulationRead.model_validate(simulation).model_dump()
        result = _result_for_simulation(session, simulation.id or 0)
        data["result"] = SimulationResultRead.model_validate(result) if result else None
        details.append(SimulationDetail(**data))
    return details


@router.get("/dashboard/summary")
def dashboard_summary(
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> dict[str, float | int | str | None]:
    statement = select(Simulation)
    if not can_view_all_records(user):
        statement = statement.where(Simulation.user_id == user.id)
    simulations = session.exec(statement.order_by(Simulation.created_at.desc())).all()
    results: list[SimulationResult] = []
    for simulation in simulations:
        result = _result_for_simulation(session, simulation.id or 0)
        if result:
            results.append(result)
    average_pv = sum(r.required_pv_power_wc for r in results) / len(results) if results else 0
    average_battery = (
        sum(r.required_battery_capacity_ah for r in results) / len(results)
        if results
        else 0
    )
    return {
        "total_simulations": len(simulations),
        "last_simulation": simulations[0].created_at.isoformat() if simulations else None,
        "average_pv_power_wc": round(average_pv, 2),
        "average_battery_capacity_ah": round(average_battery, 2),
    }


@router.get("/{simulation_id}", response_model=SimulationDetail)
def get_simulation(
    simulation_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> SimulationDetail:
    simulation = _simulation_for_user(simulation_id, user, session)
    result = _result_for_simulation(session, simulation.id or 0)
    data = SimulationRead.model_validate(simulation).model_dump()
    data["result"] = SimulationResultRead.model_validate(result) if result else None
    return SimulationDetail(**data)


@router.put("/{simulation_id}", response_model=SimulationRead)
def update_simulation(
    simulation_id: int,
    payload: SimulationUpdate,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Simulation:
    require_simulation_permission(user)
    simulation = _simulation_for_user(simulation_id, user, session)
    _site_for_user(payload.site_id, user, session)
    for field, value in payload.model_dump().items():
        setattr(simulation, field, value)
    session.add(simulation)
    session.commit()
    session.refresh(simulation)
    return simulation


@router.delete("/{simulation_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_simulation(
    simulation_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> None:
    require_simulation_permission(user)
    simulation = _simulation_for_user(simulation_id, user, session)
    result = _result_for_simulation(session, simulation.id or 0)
    if result:
        session.delete(result)
    session.delete(simulation)
    session.commit()


@router.post("/{simulation_id}/calculate", response_model=SimulationResultRead)
def calculate(
    simulation_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> SimulationResult:
    require_simulation_permission(user)
    simulation = _simulation_for_user(simulation_id, user, session)
    site = _site_for_user(simulation.site_id, user, session)
    equipment = list(
        session.exec(select(Equipment).where(Equipment.site_id == site.id)).all()
    )
    if not equipment and simulation.critical_active_power_w <= 0:
        raise HTTPException(status_code=400, detail="Add equipment before calculation")

    existing = _result_for_simulation(session, simulation.id or 0)
    if existing:
        session.delete(existing)
        session.commit()

    result = calculate_simulation(site, equipment, simulation)
    result.simulation_id = simulation.id or 0
    session.add(result)
    session.commit()
    session.refresh(result)
    return result


@router.get("/{simulation_id}/report", response_model=ReportRead)
def report(
    simulation_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> ReportRead:
    simulation = _simulation_for_user(simulation_id, user, session)
    site = _site_for_user(simulation.site_id, user, session)
    equipment = list(
        session.exec(select(Equipment).where(Equipment.site_id == site.id)).all()
    )
    result = _result_for_simulation(session, simulation.id or 0)
    return build_report_payload(
        site=site,
        simulation=simulation,
        equipment=equipment,
        result=result,
        academic_notice=ACADEMIC_NOTICE,
    )


@router.get("/{simulation_id}/report/pdf")
def report_pdf(
    simulation_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Response:
    simulation = _simulation_for_user(simulation_id, user, session)
    site = _site_for_user(simulation.site_id, user, session)
    equipment = list(
        session.exec(select(Equipment).where(Equipment.site_id == site.id)).all()
    )
    result = _result_for_simulation(session, simulation.id or 0)
    report_data = build_report_payload(
        site=site,
        simulation=simulation,
        equipment=equipment,
        result=result,
        academic_notice=ACADEMIC_NOTICE,
    )
    pdf_bytes = generate_report_pdf(report_data)
    filename = f"hayat-solar-sizer-rapport-simulation-{simulation_id}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
