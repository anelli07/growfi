from typing import TYPE_CHECKING, List, Optional
from sqlmodel import Field, Relationship, SQLModel, Enum
from sqlalchemy import Column
import enum

if TYPE_CHECKING:
    from .user import User
    from .transaction import Expense, Income


class CategoryType(str, enum.Enum):
    INCOME = "income"
    EXPENSE = "expense"


class Category(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    type: CategoryType = Field(sa_column=Column(Enum(CategoryType, native_enum=False)))

    user_id: int = Field(foreign_key="user.id")
    user: "User" = Relationship(back_populates="categories")

    expenses: List["Expense"] = Relationship(back_populates="category", sa_relationship_kwargs={"cascade": "all, delete-orphan"})
    incomes: List["Income"] = Relationship(back_populates="category", sa_relationship_kwargs={"cascade": "all, delete-orphan"})
