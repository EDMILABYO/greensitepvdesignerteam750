from fastapi import APIRouter, Depends

from app.models.user import User
from app.schemas.implementation_schema import ImplementationInput, ImplementationResult
from app.services.auth_service import get_current_user
from app.services.implementation_service import calculate_implementation

router = APIRouter(prefix="/implementation", tags=["Implementation"])


@router.post("/validate", response_model=ImplementationResult)
def validate(
    payload: ImplementationInput,
    _: User = Depends(get_current_user),
) -> ImplementationResult:
    return calculate_implementation(payload)
