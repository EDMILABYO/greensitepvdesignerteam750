from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.database import get_session
from app.models.client import Client
from app.models.user import User, UserRole
from app.schemas.client_schema import ClientCreate, ClientRead, ClientUpdate
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/clients", tags=["Clients"])


def _client_for_user(client_id: int, user: User, session: Session) -> Client:
    client = session.get(Client, client_id)
    if not client or (client.user_id != user.id and user.role != UserRole.admin):
        raise HTTPException(status_code=404, detail="Client not found")
    return client


@router.post("", response_model=ClientRead, status_code=status.HTTP_201_CREATED)
def create_client(
    payload: ClientCreate,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Client:
    client = Client(**payload.model_dump(), user_id=user.id)
    session.add(client)
    session.commit()
    session.refresh(client)
    return client


@router.get("", response_model=list[ClientRead])
def list_clients(
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> list[Client]:
    statement = select(Client)
    if user.role != UserRole.admin:
        statement = statement.where(Client.user_id == user.id)
    return list(session.exec(statement.order_by(Client.created_at.desc())).all())


@router.get("/{client_id}", response_model=ClientRead)
def get_client(
    client_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Client:
    return _client_for_user(client_id, user, session)


@router.put("/{client_id}", response_model=ClientRead)
def update_client(
    client_id: int,
    payload: ClientUpdate,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Client:
    client = _client_for_user(client_id, user, session)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(client, key, value or "")
    client.updated_at = datetime.now(timezone.utc)
    session.add(client)
    session.commit()
    session.refresh(client)
    return client


@router.delete("/{client_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_client(
    client_id: int,
    user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> None:
    client = _client_for_user(client_id, user, session)
    session.delete(client)
    session.commit()
