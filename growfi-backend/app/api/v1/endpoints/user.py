from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
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


@router.delete("/me")
def delete_current_user(
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Delete current user and all associated data.
    """
    try:
        # Удаляем пользователя (каскадное удаление удалит все связанные данные)
        db.delete(current_user)
        db.commit()
        return {"message": "User and all associated data deleted successfully"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete user: {str(e)}")
