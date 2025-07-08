from typing import TYPE_CHECKING, Optional
from sqlmodel import Field, Relationship, SQLModel
from datetime import date

if TYPE_CHECKING:
    from .user import User
    from .category import Category
    from .wallet import Wallet


class Income(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    amount: float = Field()
    transaction_date: date = Field()
    description: Optional[str] = Field(default=None)  # note
    wallet_id: Optional[int] = Field(default=None, foreign_key="wallet.id")
    type: str = Field(default="income")
    category_name: Optional[str] = Field(default=None)

    user_id: int = Field(foreign_key="user.id")
    user: "User" = Relationship(back_populates="incomes")

    category_id: int = Field(foreign_key="category.id")
    category: "Category" = Relationship(back_populates="incomes")


class Expense(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    amount: float = Field()
    transaction_date: date = Field()
    description: Optional[str] = Field(default=None)  # note
    wallet_id: Optional[int] = Field(default=None, foreign_key="wallet.id")
    type: str = Field(default="expense")
    category_name: Optional[str] = Field(default=None)

    user_id: int = Field(foreign_key="user.id")
    user: "User" = Relationship(back_populates="expenses")

    category_id: int = Field(foreign_key="category.id")
    category: "Category" = Relationship(back_populates="expenses")
