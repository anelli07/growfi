from typing import List, Tuple, Optional
from datetime import date

from sqlmodel import Session, select, func

from app.crud.base import CRUDBase
from app.models import Income, Expense, User
from app.schemas.transaction import (
    IncomeCreate,
    ExpenseCreate,
    IncomeUpdate,
    ExpenseUpdate,
)


# Удаляю все классы и переменные, связанные с CRUDIncome и CRUDExpense
