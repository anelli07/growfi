from typing import TYPE_CHECKING, Optional
from sqlmodel import Field, Relationship, SQLModel
from datetime import date

if TYPE_CHECKING:
    from .user import User
    from .category import Category
    from .wallet import Wallet


class Income(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    icon: str
    color: str
    amount: float = Field(default=0)
    transaction_date: Optional[date] = Field(default=None)
    description: Optional[str] = Field(default=None)  # note
    wallet_id: Optional[int] = Field(default=None, foreign_key="wallet.id")
    user_id: int = Field(foreign_key="user.id")
    user: "User" = Relationship(back_populates="incomes")
    category_id: Optional[int] = Field(default=None, foreign_key="category.id")
    category: "Category" = Relationship(back_populates="incomes")


class Expense(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    icon: str
    color: str
    amount: float = Field(default=0)
    transaction_date: Optional[date] = Field(default=None)
    description: Optional[str] = Field(default=None)  # note
    wallet_id: Optional[int] = Field(default=None, foreign_key="wallet.id")
    user_id: int = Field(foreign_key="user.id")
    user: "User" = Relationship(back_populates="expenses")
    category_id: Optional[int] = Field(default=None, foreign_key="category.id")
    category: "Category" = Relationship(back_populates="expenses")


class Transaction(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    from_wallet_id: Optional[int] = Field(default=None, foreign_key="wallet.id")
    to_wallet_id: Optional[int] = Field(default=None, foreign_key="wallet.id")
    from_goal_id: Optional[int] = Field(default=None, foreign_key="goal.id")
    to_goal_id: Optional[int] = Field(default=None, foreign_key="goal.id")
    from_category_id: Optional[int] = Field(default=None, foreign_key="category.id")
    to_category_id: Optional[int] = Field(default=None, foreign_key="category.id")
    amount: float = Field()
    transaction_date: date = Field()
    type: str = Field()  # income, expense, wallet_transfer, goal_transfer
    comment: Optional[str] = Field(default=None)
    name: Optional[str] = Field(default=None)
    icon: Optional[str] = Field(default=None)
    color: Optional[str] = Field(default=None)
