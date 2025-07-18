from typing import Optional, TYPE_CHECKING
from sqlmodel import SQLModel, Field, Relationship

if TYPE_CHECKING:
    from .user import User

class Wallet(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    balance: float = Field(default=0)
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    currency: str = "KZT"
    user_id: int = Field(foreign_key="user.id")
    user: "User" = Relationship(back_populates="wallets")

class WalletCreate(SQLModel):
    name: str
    balance: float = 0
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    currency: str = "KZT"

class WalletUpdate(SQLModel):
    name: Optional[str] = None
    balance: Optional[float] = None
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    currency: Optional[str] = None 