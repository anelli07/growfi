from sqlmodel import SQLModel, Field, Relationship
from typing import Optional, TYPE_CHECKING
from datetime import datetime

if TYPE_CHECKING:
    from .user import User

class Goal(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    target_amount: float
    current_amount: float = 0
    icon: str
    color: str
    currency: str = "KZT"
    user_id: int = Field(foreign_key="user.id")
    user: "User" = Relationship(back_populates="goals")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow) 