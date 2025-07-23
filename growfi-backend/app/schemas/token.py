from typing import Optional
from sqlmodel import SQLModel


class Token(SQLModel):
    access_token: str
    refresh_token: str
    token_type: str


class TokenData(SQLModel):
    username: Optional[str] = None


class GoogleToken(SQLModel):
    token: str


class AppleToken(SQLModel):
    token: str
    full_name: Optional[str] = None
