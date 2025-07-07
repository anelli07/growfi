from datetime import date
from typing import Optional

from sqlmodel import SQLModel


# Shared properties
class TransactionBase(SQLModel):
    transaction_date: date
    amount: float
    description: Optional[str] = None
    category_id: int


# Properties to receive on item creation
class IncomeCreate(TransactionBase):
    pass


class ExpenseCreate(TransactionBase):
    pass


# Properties to receive on item update
class TransactionUpdate(SQLModel):
    transaction_date: Optional[date] = None
    amount: Optional[float] = None
    description: Optional[str] = None
    category_id: Optional[int] = None


class IncomeUpdate(TransactionUpdate):
    pass


class ExpenseUpdate(TransactionUpdate):
    pass


# Properties to return to client
class Income(TransactionBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True


class Expense(TransactionBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
