from fastapi import APIRouter, Depends

from app.models.user import User
from app.schemas.maintenance_schema import MaintenanceInput, MaintenanceResult
from app.services.auth_service import get_current_user
from app.services.maintenance_service import evaluate_maintenance

router = APIRouter(prefix="/maintenance", tags=["Maintenance"])


@router.post("/evaluate", response_model=MaintenanceResult)
def evaluate(
    payload: MaintenanceInput,
    _: User = Depends(get_current_user),
) -> MaintenanceResult:
    return evaluate_maintenance(payload)
