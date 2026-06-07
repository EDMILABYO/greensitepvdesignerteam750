from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.database import get_session
from app.models.equipment import Equipment
from app.models.site import Site
from app.models.user import User, UserRole
from app.schemas.equipment_schema import EquipmentCreate, EquipmentRead, EquipmentUpdate
from app.services.auth_service import get_current_user

router = APIRouter(tags=["Equipment"])


def _assert_site_access(site_id: int, user: User, session: Session) -> Site:
    site = session.get(Site, site_id)
    if not site or (site.user_id != user.id and user.role != UserRole.admin):
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
    _assert_site_access(site_id, user, session)
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
    equipment = _equipment_for_user(equipment_id, user, session)
    for key, value in payload.model_dump(exclude_unset=True).items():
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
    equipment = _equipment_for_user(equipment_id, user, session)
    session.delete(equipment)
    session.commit()
