from fastapi import APIRouter, Depends

from app.models.user import User
from app.schemas.design_schema import DesignInput, DesignResult
from app.services.auth_service import get_current_user
from app.services.design_service import calculate_design

router = APIRouter(prefix="/design", tags=["Design"])


@router.post("/calculate", response_model=DesignResult)
def calculate(
    payload: DesignInput,
    _: User = Depends(get_current_user),
) -> DesignResult:
    return calculate_design(payload)
