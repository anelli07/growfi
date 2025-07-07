from typing import Any
from fastapi import APIRouter, Depends
from sqlmodel import Session
from datetime import date, timedelta

from app import models, schemas
from app.api import deps
from app.crud.crud_dashboard import get_dashboard_data

router = APIRouter()


@router.get("/", response_model=schemas.DashboardData)
def read_dashboard_data(
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
    start_date: date = None,
    end_date: date = None,
) -> Any:
    """
    Retrieve dashboard data for a date range.
    Defaults to the current month if no dates are provided.
    """
    if start_date is None or end_date is None:
        today = date.today()
        start_date = today.replace(day=1)
        end_date = (start_date + timedelta(days=31)).replace(day=1) - timedelta(days=1)

    return get_dashboard_data(
        db=db, user=current_user, start_date=start_date, end_date=end_date
    )
