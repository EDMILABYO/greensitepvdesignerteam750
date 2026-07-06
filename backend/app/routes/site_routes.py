from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.database import get_session
from app.models.equipment import Equipment
from app.models.site import Site
from app.models.user import User
from app.schemas.site_schema import SiteCreate, SiteRead, SiteUpdate
from app.services.auth_service import (
    can_view_all_records,
    get_current_user,
    require_site_data_permission,
)

router = APIRouter(prefix="/sites", tags=["Sites"])


def _validate_site_layout(site: Site, session: Session) -> None:
    one_dimension_missing = (site.layout_length_m > 0) != (site.layout_width_m > 0)
    if one_dimension_missing:
        raise HTTPException(
            status_code=422,
            detail="Renseignez ensemble la longueur et la largeur de la zone d'implantation.",
        )
    if site.layout_length_m <= 0 or site.layout_width_m <= 0:
        return

    layout_area = site.layout_length_m * site.layout_width_m
    if site.available_area_m2 > 0 and layout_area > site.available_area_m2 + 0.01:
        raise HTTPException(
            status_code=422,
            detail="La zone d'implantation depasse la surface utile du site.",
        )

    if site.id is None:
        return
    equipment = session.exec(
        select(Equipment).where(Equipment.site_id == site.id)
    ).all()
    for item in equipment:
        if (
            item.position_x_m + item.footprint_width_m > site.layout_width_m
            or item.position_y_m + item.footprint_length_m > site.layout_length_m
        ):
            raise HTTPException(
                status_code=422,
                detail=f"La nouvelle zone exclut l'equipement « {item.name} ».",
            )


def _derived_available_area(data: SiteCreate | SiteUpdate, fallback: float = 0) -> float:
    values = data.model_dump(exclude_unset=False)
    total_area = values.get("total_area_m2") or 0
    tower_area = values.get("tower_area_m2") or 0
    rack_area = values.get("rack_area_m2") or 0
    generator_area = values.get("generator_area_m2") or 0
    other_blocked_area = values.get("other_blocked_area_m2") or 0
    usable_area_ratio = values.get("usable_area_ratio") or 1
    explicit_available = values.get("available_area_m2")
    if explicit_available and explicit_available > 0:
        return explicit_available
    free_area = total_area - tower_area - rack_area - generator_area - other_blocked_area
    return max(free_area, 0) * usable_area_ratio if total_area > 0 else fallback


def _site_for_user(site_id: int, user: User, session: Session) -> Site:
    site = session.get(Site, site_id)
    if not site or (site.user_id != user.id and not can_view_all_records(user)):
        raise HTTPException(status_code=404, detail="Site not found")
    return site


@router.post("", response_model=SiteRead, status_code=status.HTTP_201_CREATED)
def create_site(
    payload: SiteCreate,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Site:
    require_site_data_permission(user)
    payload_data = payload.model_dump()
    payload_data["available_area_m2"] = _derived_available_area(payload)
    site = Site(**payload_data, user_id=user.id)
    _validate_site_layout(site, session)
    session.add(site)
    session.commit()
    session.refresh(site)
    return site


@router.get("", response_model=list[SiteRead])
def list_sites(
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> list[Site]:
    statement = select(Site)
    if not can_view_all_records(user):
        statement = statement.where(Site.user_id == user.id)
    return list(session.exec(statement.order_by(Site.created_at.desc())).all())


@router.get("/{site_id}", response_model=SiteRead)
def get_site(
    site_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Site:
    return _site_for_user(site_id, user, session)


@router.put("/{site_id}", response_model=SiteRead)
def update_site(
    site_id: int,
    payload: SiteUpdate,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Site:
    require_site_data_permission(user)
    site = _site_for_user(site_id, user, session)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(site, key, value)
    site.available_area_m2 = _derived_available_area(payload, fallback=site.available_area_m2)
    site.updated_at = datetime.now(timezone.utc)
    _validate_site_layout(site, session)
    session.add(site)
    session.commit()
    session.refresh(site)
    return site


@router.delete("/{site_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_site(
    site_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> None:
    require_site_data_permission(user)
    site = _site_for_user(site_id, user, session)
    session.delete(site)
    session.commit()
