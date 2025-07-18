import re
from typing import Optional

from pydantic import EmailStr, validator
from sqlmodel import Field, SQLModel


# Shared properties
class UserBase(SQLModel):
    email: EmailStr = Field(unique=True, index=True)
    is_active: bool = Field(default=True)
    is_superuser: bool = Field(default=False)
    full_name: Optional[str] = None


# Properties to receive via API on creation
class UserCreate(SQLModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None

    @validator("password")
    def validate_password(cls, v, values, **kwargs):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long")
        if not re.search(r"[A-Za-z]", v):
            raise ValueError("Password must contain at least one letter")
        if not re.search(r"\d", v):
            raise ValueError("Password must contain at least one number")
        if (
            "email" in values
            and values.get("email")
            and values["email"].split("@")[0] in v
        ):
            raise ValueError("Password should not contain your email username")
        return v


# Properties to receive via API on update
class UserUpdate(UserBase):
    password: Optional[str] = None


class UserInDBBase(UserBase):
    id: Optional[int] = Field(default=None, primary_key=True)

    class Config:
        from_attributes = True


# Additional properties to return via API
class User(UserInDBBase):
    pass


# Additional properties stored in DB
class UserInDB(UserInDBBase):
    hashed_password: Optional[str] = None
    google_id: Optional[str] = Field(default=None, unique=True, index=True)


class PasswordResetRequest(SQLModel):
    email: EmailStr

class PasswordResetConfirm(SQLModel):
    token: str
    new_password: str
