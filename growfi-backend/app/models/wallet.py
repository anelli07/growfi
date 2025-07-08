from typing import Optional
from sqlmodel import SQLModel, Field

class Wallet(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    balance: float = 0
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    currency: str = "KZT"
    user_id: int = Field(foreign_key="user.id")

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