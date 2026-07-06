from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.database import get_session
from app.models.equipment import Equipment
from app.models.site import Site
from app.models.user import User
from app.schemas.equipment_schema import EquipmentCreate, EquipmentRead, EquipmentUpdate
from app.services.auth_service import (
    can_view_all_records,
    get_current_user,
    require_site_data_permission,
)

router = APIRouter(tags=["Equipment"])


def _validate_placement(
    site: Site,
    candidate: EquipmentCreate,
    session: Session,
    excluded_equipment_id: int | None = None,
) -> None:
    if candidate.footprint_length_m <= 0 or candidate.footprint_width_m <= 0:
        return
    if site.layout_length_m <= 0 or site.layout_width_m <= 0:
        raise HTTPException(
            status_code=422,
            detail="Renseignez d'abord la longueur et la largeur de la zone d'implantation du site.",
        )

    candidate_right = candidate.position_x_m + candidate.footprint_width_m
    candidate_bottom = candidate.position_y_m + candidate.footprint_length_m
    if candidate_right > site.layout_width_m or candidate_bottom > site.layout_length_m:
        raise HTTPException(
            status_code=422,
            detail="L'equipement depasse les limites de la zone d'implantation du site.",
        )

    existing_equipment = session.exec(
        select(Equipment).where(Equipment.site_id == site.id)
    ).all()
    for existing in existing_equipment:
        if existing.id == excluded_equipment_id:
            continue
        if existing.footprint_length_m <= 0 or existing.footprint_width_m <= 0:
            continue
        overlaps = (
            candidate.position_x_m < existing.position_x_m + existing.footprint_width_m
            and candidate_right > existing.position_x_m
            and candidate.position_y_m < existing.position_y_m + existing.footprint_length_m
            and candidate_bottom > existing.position_y_m
        )
        if overlaps:
            raise HTTPException(
                status_code=422,
                detail=f"L'emplacement chevauche l'equipement « {existing.name} ».",
            )


def _assert_site_access(site_id: int, user: User, session: Session) -> Site:
    site = session.get(Site, site_id)
    if not site or (site.user_id != user.id and not can_view_all_records(user)):
        raise HTTPException(status_code=404, detail="Site not found")
    return site


def _equipment_for_user(equipment_id: int, user: User, session: Session) -> Equipment:
    equipment = session.get(Equipment, equipment_id)
    if not equipment:
        raise HTTPException(status_code=404, detail="Equipment not found")
    _assert_site_access(equipment.site_id, user, session)
    return equipment


@router.post(
    "/sites/{site_id}/equipment",
    response_model=EquipmentRead,
    status_code=status.HTTP_201_CREATED,
)
def add_equipment(
    site_id: int,
    payload: EquipmentCreate,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Equipment:
    require_site_data_permission(user)
    site = _assert_site_access(site_id, user, session)
    _validate_placement(site, payload, session)
    equipment = Equipment(**payload.model_dump(), site_id=site_id)
    session.add(equipment)
    session.commit()
    session.refresh(equipment)
    return equipment


@router.get("/sites/{site_id}/equipment", response_model=list[EquipmentRead])
def list_equipment(
    site_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> list[Equipment]:
    _assert_site_access(site_id, user, session)
    return list(
        session.exec(
            select(Equipment)
            .where(Equipment.site_id == site_id)
            .order_by(Equipment.created_at)
        ).all()
    )


@router.put("/equipment/{equipment_id}", response_model=EquipmentRead)
def update_equipment(
    equipment_id: int,
    payload: EquipmentUpdate,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Equipment:
    require_site_data_permission(user)
    equipment = _equipment_for_user(equipment_id, user, session)
    update_data = payload.model_dump(exclude_unset=True)
    merged_data = {
        key: update_data.get(key, getattr(equipment, key))
        for key in EquipmentCreate.model_fields
    }
    _validate_placement(
        _assert_site_access(equipment.site_id, user, session),
        EquipmentCreate(**merged_data),
        session,
        excluded_equipment_id=equipment_id,
    )
    for key, value in update_data.items():
        setattr(equipment, key, value)
    equipment.updated_at = datetime.now(timezone.utc)
    session.add(equipment)
    session.commit()
    session.refresh(equipment)
    return equipment


@router.delete("/equipment/{equipment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_equipment(
    equipment_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> None:
    require_site_data_permission(user)
    equipment = _equipment_for_user(equipment_id, user, session)
    session.delete(equipment)
    session.commit()
