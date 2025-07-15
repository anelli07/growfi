from datetime import date
from typing import Optional

from sqlmodel import SQLModel
from pydantic import ConfigDict


# Shared properties
class TransactionBase(SQLModel):
    name: str
    icon: str
    color: str
    description: Optional[str] = None  # note


# Properties to receive on item creation
class IncomeCreate(SQLModel):
    name: str
    icon: str
    color: str
    amount: float = 0
    transaction_date: Optional[date] = None
    category_id: Optional[int] = None


class ExpenseCreate(SQLModel):
    name: str
    icon: str
    color: str
    amount: float = 0
    transaction_date: Optional[date] = None
    category_id: Optional[int] = None
    wallet_id: Optional[int] = None


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
    amount: float
    transaction_date: Optional[date] = None
    wallet_id: Optional[int] = None
    category_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


class Expense(TransactionBase):
    id: int
    user_id: int
    amount: float
    transaction_date: Optional[date] = None
    wallet_id: Optional[int] = None
    category_id: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


class TransactionBaseSchema(SQLModel):
    user_id: int
    from_wallet_id: Optional[int] = None
    to_wallet_id: Optional[int] = None
    from_goal_id: Optional[int] = None
    to_goal_id: Optional[int] = None
    from_category_id: Optional[int] = None
    to_category_id: Optional[int] = None
    amount: float
    transaction_date: date
    type: str
    comment: Optional[str] = None

class TransactionCreate(TransactionBaseSchema):
    pass

class TransactionRead(TransactionBaseSchema):
    id: int

    class Config:
        from_attributes = True

class ExpenseAssign(SQLModel):
    wallet_id: int
    amount: float
    date: date
    comment: Optional[str] = None
    category_id: Optional[int] = None
