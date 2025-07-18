from typing import TYPE_CHECKING, List, Optional
from sqlmodel import Field, Relationship, SQLModel
from datetime import datetime

if TYPE_CHECKING:
    from .category import Category
    from .transaction import Income, Expense


class UserBase(SQLModel):
    full_name: Optional[str] = None
    email: str = Field(unique=True, index=True)
    is_active: bool = Field(default=True)
    is_superuser: bool = Field(default=False)
    is_email_verified: bool = Field(default=False)
    google_id: Optional[str] = Field(default=None, unique=True)
    apple_id: Optional[str] = Field(default=None, unique=True)
    timezone: str = Field(default="UTC")


class User(UserBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    hashed_password: Optional[str] = Field(default=None)  # Optional for Google Sign-In
    refresh_token: Optional[str] = Field(default=None, index=True)
    email_verification_code: Optional[str] = Field(default=None, index=True)
    email_verification_code_sent_at: Optional[datetime] = Field(default=None)
    reset_password_token: Optional[str] = Field(default=None, index=True)
    reset_password_token_sent_at: Optional[datetime] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    categories: List["Category"] = Relationship(back_populates="user")
    incomes: List["Income"] = Relationship(back_populates="user")
    expenses: List["Expense"] = Relationship(back_populates="user")
