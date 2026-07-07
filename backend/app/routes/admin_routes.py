from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session, select

from app.database import get_session
from app.models.user import User, UserRole
from app.schemas.user_schema import AdminUserCreate, AdminUserUpdate, UserRead
from app.services.auth_service import can_manage_users, get_current_user
from app.utils.security import hash_password

router = APIRouter(prefix="/admin", tags=["Admin"])
SUPPORTED_USER_ROLES = ", ".join(role.value for role in UserRole)


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not can_manage_users(user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return user


@router.get("/users", response_model=list[UserRead])
def list_users(
    _: User = Depends(require_admin),
    session: Session = Depends(get_session),
) -> list[User]:
    return session.exec(select(User).order_by(User.created_at.desc())).all()


@router.post("/users", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def create_user(
    payload: AdminUserCreate,
    _: User = Depends(require_admin),
    session: Session = Depends(get_session),
) -> User:
    existing = session.exec(select(User).where(User.email == payload.email.lower())).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    user = User(
        full_name=payload.full_name,
        email=payload.email.lower(),
        hashed_password=hash_password(payload.password),
        role=payload.role,
    )
    session.add(user)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise HTTPException(
            status_code=400,
            detail=(
                "Database rejected the user record. "
                f"Supported roles: {SUPPORTED_USER_ROLES}"
            ),
        ) from exc
    session.refresh(user)
    return user


@router.put("/users/{user_id}", response_model=UserRead)
def update_user(
    user_id: int,
    payload: AdminUserUpdate,
    current_admin: User = Depends(require_admin),
    session: Session = Depends(get_session),
) -> User:
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if payload.email:
        existing = session.exec(
            select(User).where(User.email == payload.email.lower(), User.id != user_id)
        ).first()
        if existing:
            raise HTTPException(status_code=409, detail="Email already registered")

    updates = payload.model_dump(exclude_unset=True)
    if "full_name" in updates:
        user.full_name = updates["full_name"]
    if "email" in updates and updates["email"] is not None:
        user.email = str(updates["email"]).lower()
    if "role" in updates and updates["role"] is not None:
        user.role = updates["role"]
    if "password" in updates and updates["password"]:
        user.hashed_password = hash_password(updates["password"])

    if user.id == current_admin.id and user.role != UserRole.admin:
        raise HTTPException(status_code=400, detail="Admin cannot remove own admin role")

    session.add(user)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise HTTPException(
            status_code=400,
            detail=(
                "Database rejected the user update. "
                f"Supported roles: {SUPPORTED_USER_ROLES}"
            ),
        ) from exc
    session.refresh(user)
    return user


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    current_admin: User = Depends(require_admin),
    session: Session = Depends(get_session),
) -> None:
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.id == current_admin.id:
        raise HTTPException(status_code=400, detail="Admin cannot delete own account")
    session.delete(user)
    session.commit()
