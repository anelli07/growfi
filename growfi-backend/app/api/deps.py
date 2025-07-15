from typing import Generator, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from pydantic import ValidationError, BaseModel
from sqlmodel import Session

from app import models, schemas
from app.core import security
from app.core.config import settings
from app.db.session import engine

reusable_oauth2 = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")


class TokenData(BaseModel):
    sub: Optional[str] = None


def get_db() -> Generator:
    with Session(engine, expire_on_commit=True) as session:
        yield session


def get_current_active_user(
    db: Session = Depends(get_db), token: str = Depends(reusable_oauth2)
) -> models.User:
    print(f"[DEBUG] get_current_active_user: token='{token[:40]}...' (len={len(token)})")
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[security.ALGORITHM]
        )
        token_data = schemas.TokenPayload(**payload)
    except (JWTError, ValidationError) as e:
        print(f"[DEBUG] get_current_active_user: JWTError/ValidationError: {e}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        )
    user = db.get(models.User, token_data.sub)
    print(f"[DEBUG] get_current_active_user: user={getattr(user, 'id', None)}, email={getattr(user, 'email', None)}")
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user.")
    return user
