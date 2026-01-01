from fastapi import APIRouter, Depends

from auth.cognito import cognito_auth_required
from services.health_service import get_status

router = APIRouter()


@router.get("/")
def read_root() -> dict[str, str]:
    return get_status()


@router.get("/protected")
def read_protected(_claims: dict[str, object] = Depends(cognito_auth_required)) -> dict[str, str]:
    return {"status": "authorized"}
