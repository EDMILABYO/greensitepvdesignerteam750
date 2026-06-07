from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.database import get_session
from app.models.site import Site
from app.models.user import User, UserRole
from app.schemas.site_schema import SiteCreate, SiteRead, SiteUpdate
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/sites", tags=["Sites"])


def _site_for_user(site_id: int, user: User, session: Session) -> Site:
    site = session.get(Site, site_id)
    if not site or (site.user_id != user.id and user.role != UserRole.admin):
        raise HTTPException(status_code=404, detail="Site not found")
    return site


@router.post("", response_model=SiteRead, status_code=status.HTTP_201_CREATED)
def create_site(
    payload: SiteCreate,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Site:
    site = Site(**payload.model_dump(), user_id=user.id)
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
    if user.role != UserRole.admin:
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
    site = _site_for_user(site_id, user, session)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(site, key, value)
    site.updated_at = datetime.now(timezone.utc)
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
    site = _site_for_user(site_id, user, session)
    session.delete(site)
    session.commit()

