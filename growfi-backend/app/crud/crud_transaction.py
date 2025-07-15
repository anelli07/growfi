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
from app.models.transaction import Transaction
from app.schemas.transaction import TransactionCreate, TransactionRead


# Удаляю все классы и переменные, связанные с CRUDIncome и CRUDExpense

class CRUDTransaction(CRUDBase[Transaction, TransactionCreate, TransactionRead]):
    def get_multi_by_user(self, db: Session, user_id: int) -> list[Transaction]:
        return db.query(Transaction).filter(Transaction.user_id == user_id).all()

transaction = CRUDTransaction(Transaction)
