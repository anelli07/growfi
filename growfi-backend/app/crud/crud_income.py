from typing import List, Tuple, Optional
from datetime import date
from sqlmodel import Session, select, func
from app.crud.base import CRUDBase
from app.models import Income, User, Wallet
from app.schemas.transaction import IncomeCreate, IncomeUpdate
from app.crud.crud_transaction import transaction
from app.schemas.transaction import TransactionCreate

import logging
logger = logging.getLogger(__name__)

class CRUDIncome(CRUDBase[Income, IncomeCreate, IncomeUpdate]):
    def create_with_user(self, db: Session, *, obj_in: IncomeCreate, user: User) -> Income:
        db_obj = Income(**obj_in.dict(), user_id=user.id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_multi_by_user(
        self,
        db: Session,
        *,
        user: User,
        page: int = 1,
        size: int = 100,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> Tuple[List[Income], int]:
        query = select(self.model).where(self.model.user_id == user.id)
        if start_date:
            query = query.where(self.model.transaction_date >= start_date)
        if end_date:
            query = query.where(self.model.transaction_date <= end_date)
        count_query = select(func.count()).select_from(query.subquery())
        total = db.exec(count_query).one()
        items_query = query.offset((page - 1) * size).limit(size)
        items = db.exec(items_query).all()
        return items, total

    def assign_income_to_wallet(
        self, db: Session, *, income_id: int, wallet_id: int, amount: float, category_id: Optional[int] = None
    ) -> Income:
        logger.debug(f"assign_income_to_wallet: income_id={income_id}, wallet_id={wallet_id}, amount={amount}, category_id={category_id}")
        try:
            income = db.get(Income, income_id)
            if not income:
                logger.warning(f"Income not found: income_id={income_id}")
                raise ValueError("Income not found")
            wallet = db.get(Wallet, wallet_id)
            if not wallet:
                logger.warning(f"Wallet not found: wallet_id={wallet_id}")
                raise ValueError("Wallet not found")
            wallet.balance += amount
            logger.debug(f"Перед коммитом: wallet.id={wallet.id}, balance={wallet.balance}")
            db.add(wallet)
            income.wallet_id = wallet_id
            income.amount += amount
            if category_id is not None:
                income.category_id = category_id
            db.add(income)
            db.commit()
            db.expire_all()
            db.refresh(income)
            db.refresh(wallet)
            logger.debug(f"После коммита: wallet.id={wallet.id}, balance={wallet.balance}")
            # Создаём Transaction
            transaction_obj = TransactionCreate(
                user_id=income.user_id,
                from_wallet_id=None,
                to_wallet_id=wallet_id,
                from_goal_id=None,
                to_goal_id=None,
                from_category_id=None,
                to_category_id=category_id,
                amount=amount,
                transaction_date=income.transaction_date or date.today(),
                type="income",
                comment=income.description,
                name=income.name,
                icon=income.icon,
                color=income.color
            )
            logger.debug(f"Creating transaction: {transaction_obj}")
            transaction.create(db, obj_in=transaction_obj)
            logger.info(f"Income assigned and transaction created: income_id={income_id}")
            return income
        except Exception as e:
            logger.exception(f"assign_income_to_wallet error: {e}")
            raise


income = CRUDIncome(Income) 