from datetime import date
from typing import Optional

from sqlmodel import SQLModel


# Shared properties
class TransactionBase(SQLModel):
    name: str
    icon: str
    color: str
    description: Optional[str] = None  # note


# Properties to receive on item creation
class IncomeCreate(TransactionBase):
    pass


class ExpenseCreate(TransactionBase):
    pass


# Properties to receive on item update
class IncomeUpdate(TransactionBase):
    pass


class ExpenseUpdate(TransactionBase):
    pass


# Assign schemas
class IncomeAssign(SQLModel):
    wallet_id: int
    amount: float
    date: date
    comment: Optional[str] = None
    category_id: Optional[int] = None

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
