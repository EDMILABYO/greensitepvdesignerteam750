from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlmodel import Session, select

from app.config import get_settings
from app.database import get_session
from app.models.user import User, UserRole


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_user(
    token: str = Depends(oauth2_scheme),
    session: Session = Depends(get_session),
) -> User:
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Authentication required",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token,
            get_settings().secret_key,
            algorithms=[get_settings().algorithm],
        )
        user_id = int(payload.get("sub"))
    except (JWTError, TypeError, ValueError):
        raise credentials_error from None

    user = session.get(User, user_id)
    if not user:
        raise credentials_error
    return user


def get_user_by_email(session: Session, email: str) -> User | None:
    return session.exec(select(User).where(User.email == email.lower())).first()


def can_manage_users(user: User) -> bool:
    return user.role == UserRole.admin


def can_view_all_records(user: User) -> bool:
    return user.role in {UserRole.admin, UserRole.manager}


def can_manage_site_data(user: User) -> bool:
    return user.role in {
        UserRole.admin,
        UserRole.engineer,
        UserRole.operator,
        UserRole.student,
    }


def can_manage_simulations(user: User) -> bool:
    return user.role in {
        UserRole.admin,
        UserRole.engineer,
        UserRole.student,
    }


def require_site_data_permission(user: User) -> User:
    if not can_manage_site_data(user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions for site data management",
        )
    return user


def require_simulation_permission(user: User) -> User:
    if not can_manage_simulations(user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions for simulation management",
        )
    return user
