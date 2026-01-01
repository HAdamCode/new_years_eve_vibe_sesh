from fastapi import APIRouter

from services.health_service import get_status

router = APIRouter()


@router.get("/")
def read_root() -> dict[str, str]:
    return get_status()
