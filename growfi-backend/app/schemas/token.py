from typing import Optional
from sqlmodel import SQLModel


class Token(SQLModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenPayload(SQLModel):
    sub: Optional[int] = None


class GoogleToken(SQLModel):
    token: str
