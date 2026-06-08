from fastapi import APIRouter, Depends

from app.models.user import User
from app.schemas.feasibility_schema import FeasibilityInput, FeasibilityResult
from app.services.auth_service import get_current_user
from app.services.feasibility_service import calculate_feasibility

router = APIRouter(prefix="/feasibility", tags=["Feasibility"])


@router.post("/calculate", response_model=FeasibilityResult)
def calculate(
    payload: FeasibilityInput,
    _: User = Depends(get_current_user),
) -> FeasibilityResult:
    return calculate_feasibility(payload)
