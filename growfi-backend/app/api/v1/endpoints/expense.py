from typing import Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session
from datetime import date
import math

from app import crud, models, schemas
from app.api import deps
from app.schemas.page import Page

router = APIRouter()


@router.get("/", response_model=Page[schemas.Expense])
def read_expenses(
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(50, ge=1, le=100, description="Page size"),
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
) -> Any:
    """
    Retrieve expenses for the current user with pagination and filtering.
    """
    items, total = crud.expense.get_multi_by_user(
        db=db,
        user=current_user,
        page=page,
        size=size,
        start_date=start_date,
        end_date=end_date,
    )
    return Page(
        items=items,
        total=total,
        page=page,
        size=size,
        pages=math.ceil(total / size) if total > 0 else 0,
    )


@router.post("/", response_model=schemas.Expense)
def create_expense(
    *,
    db: Session = Depends(deps.get_db),
    expense_in: schemas.ExpenseCreate,
    current_user: models.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Create new expense for the current user.
    """
    expense = crud.expense.create_with_user(db=db, obj_in=expense_in, user=current_user)
    return expense


@router.put("/{id}", response_model=schemas.Expense)
def update_expense(
    *,
    db: Session = Depends(deps.get_db),
    id: int,
    expense_in: schemas.ExpenseUpdate,
    current_user: models.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Update an expense.
    """
    expense = crud.expense.get(db=db, id=id)
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    if expense.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    expense = crud.expense.update(db=db, db_obj=expense, obj_in=expense_in)
    return expense


@router.delete("/{id}", response_model=schemas.Expense)
def delete_expense(
    *,
    db: Session = Depends(deps.get_db),
    id: int,
    current_user: models.User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Delete an expense.
    """
    expense = crud.expense.get(db=db, id=id)
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    if expense.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    expense = crud.expense.remove(db=db, id=id)
    return expense
