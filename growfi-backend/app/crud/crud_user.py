# from typing import Any, Dict, Optional, Union
from typing import Optional
import uuid
import random
from datetime import datetime, timedelta

from sqlmodel import Session
from app.core.security import get_password_hash, verify_password
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate
from app.crud.base import CRUDBase


class CRUDUser(CRUDBase[User, UserCreate, UserUpdate]):
    def get_by_email(self, db: Session, *, email: str) -> Optional[User]:
        return db.query(User).filter(User.email == email).first()

    def get_by_google_id(self, db: Session, *, google_id: str) -> Optional[User]:
        return db.query(User).filter(User.google_id == google_id).first()

    def get_by_apple_id(self, db: Session, *, apple_id: str) -> Optional[User]:
        return db.query(User).filter(User.apple_id == apple_id).first()

    def create(self, db: Session, *, obj_in: UserCreate) -> User:
        code = str(random.randint(100000, 999999))
        db_obj = User(
            email=obj_in.email,
            hashed_password=get_password_hash(obj_in.password),
            full_name=obj_in.full_name,
            email_verification_code=code,
            email_verification_code_sent_at=datetime.utcnow(),
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def create_with_google(
        self, db: Session, *, full_name: Optional[str], email: str, google_id: str
    ) -> User:
        db_obj = User(
            full_name=full_name,
            email=email,
            google_id=google_id,
            is_email_verified=True,
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def create_with_apple(
        self, db: Session, *, full_name: Optional[str], email: str, apple_id: str
    ) -> User:
        db_obj = User(
            full_name=full_name,
            email=email,
            apple_id=apple_id,
            is_email_verified=True,
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def update(self, db: Session, *, db_obj: User, obj_in: UserUpdate) -> User:
        update_data = obj_in.dict(exclude_unset=True)
        return super().update(db, db_obj=db_obj, obj_in=update_data)

    def authenticate(self, db: Session, *, email: str, password: str) -> Optional[User]:
        user = self.get_by_email(db, email=email)
        if not user:
            return None
        if not user.hashed_password:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user

    def is_active(self, user: User) -> bool:
        return user.is_active

    def verify_email_code(self, db: Session, *, email: str, code: str) -> bool:
        user = self.get_by_email(db, email=email)
        if not user or user.email_verification_code != code:
            return False
        # 10 минут на ввод кода
        if (datetime.utcnow() - user.email_verification_code_sent_at).total_seconds() > 600:
            return False
        user.is_email_verified = True
        user.email_verification_code = None
        user.email_verification_code_sent_at = None
        db.add(user)
        db.commit()
        db.refresh(user)
        return True

    def resend_verification_code(self, db: Session, *, email: str) -> Optional[str]:
        user = self.get_by_email(db, email=email)
        if not user:
            return None
        code = str(random.randint(100000, 999999))
        user.email_verification_code = code
        user.email_verification_code_sent_at = datetime.utcnow()
        db.add(user)
        db.commit()
        db.refresh(user)
        return code

    def generate_reset_password_token(self, db: Session, *, email: str) -> Optional[str]:
        user = self.get_by_email(db, email=email)
        if not user:
            return None
        token = str(uuid.uuid4())
        user.reset_password_token = token
        user.reset_password_token_sent_at = datetime.utcnow()
        db.add(user)
        db.commit()
        db.refresh(user)
        return token

    def reset_password(self, db: Session, *, token: str, new_password: str) -> bool:
        user = db.query(User).filter(User.reset_password_token == token).first()
        if not user:
            return False
        # 1 час на сброс пароля
        if (datetime.utcnow() - user.reset_password_token_sent_at).total_seconds() > 3600:
            return False
        user.hashed_password = get_password_hash(new_password)
        user.reset_password_token = None
        user.reset_password_token_sent_at = None
        db.add(user)
        db.commit()
        db.refresh(user)
        return True

    def delete_by_id(self, db: Session, user_id: int) -> None:
        user = db.query(User).filter(User.id == user_id).first()
        if user:
            # Force-load все связи для ORM-каскада
            _ = user.wallets, user.goals, user.categories, user.expenses, user.incomes
            db.delete(user)
            db.commit()


user = CRUDUser(User)
