from typing import Optional
from pydantic import BaseModel

class WalletBase(BaseModel):
    name: str
    balance: float = 0
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    currency: str = "KZT"

class WalletCreate(WalletBase):
    pass

class WalletUpdate(BaseModel):
    name: Optional[str] = None
    balance: Optional[float] = None
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    currency: Optional[str] = None

class Wallet(WalletBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True 