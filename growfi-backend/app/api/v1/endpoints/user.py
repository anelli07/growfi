from typing import Any
from fastapi import APIRouter, Depends
from app import models, schemas
from app.api import deps

router = APIRouter()


@router.get("/me", response_model=schemas.User)
def read_users_me(
    current_user: models.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get current user.
    """
    return current_user
