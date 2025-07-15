from typing import List, Optional
from sqlmodel import Session, select
from app.models.wallet import Wallet
from app.schemas.wallet import WalletCreate, WalletUpdate
from app.models.goal import Goal
from app.models.transaction import Expense
from app.crud.crud_transaction import transaction
from app.schemas.transaction import TransactionCreate
from datetime import date

class CRUDWallet:
    def get_multi_by_user(self, db: Session, user_id: int) -> List[Wallet]:
        return db.exec(select(Wallet).where(Wallet.user_id == user_id)).all()

    def create_with_user(self, db: Session, obj_in: WalletCreate, user_id: int) -> Wallet:
        db_obj = Wallet(**obj_in.dict(), user_id=user_id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def update(self, db: Session, db_obj: Wallet, obj_in: WalletUpdate) -> Wallet:
        obj_data = obj_in.dict(exclude_unset=True)
        for field, value in obj_data.items():
            setattr(db_obj, field, value)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def remove(self, db: Session, id: int) -> Optional[Wallet]:
        obj = db.get(Wallet, id)
        if obj:
            db.delete(obj)
            db.commit()
        return obj

    def assign_goal(self, db: Session, *, wallet_id: int, goal_id: int, amount: float, date: str, comment: str = None):
        wallet = db.get(Wallet, wallet_id)
        goal = db.get(Goal, goal_id)
        if not wallet:
            raise ValueError("Wallet not found")
        if not goal:
            raise ValueError("Goal not found")
        if wallet.balance < amount:
            raise ValueError("Not enough funds in wallet")
        wallet.balance -= amount
        goal.current_amount += amount
        db.add(wallet)
        db.add(goal)
        db.commit()
        db.expire_all()
        db.refresh(wallet)
        db.refresh(goal)
        # Создаём Transaction
        transaction_obj = TransactionCreate(
            user_id=wallet.user_id,
            from_wallet_id=wallet_id,
            to_wallet_id=None,
            from_goal_id=None,
            to_goal_id=goal_id,
            from_category_id=None,
            to_category_id=None,
            amount=amount,
            transaction_date=date,
            type="goal_transfer",
            comment=comment
        )
        transaction.create(db, obj_in=transaction_obj)
        return wallet

    def assign_expense(self, db: Session, *, wallet_id: int, expense_id: int, amount: float, date: str, comment: str = None):
        wallet = db.get(Wallet, wallet_id)
        expense = db.get(Expense, expense_id)
        if not wallet:
            raise ValueError("Wallet not found")
        if not expense:
            raise ValueError("Expense not found")
        if wallet.balance < amount:
            raise ValueError("Not enough funds in wallet")
        wallet.balance -= amount
        expense.amount += amount
        db.add(wallet)
        db.add(expense)
        db.commit()
        db.expire_all()
        db.refresh(wallet)
        db.refresh(expense)
        # Создаём Transaction
        transaction_obj = TransactionCreate(
            user_id=wallet.user_id,
            from_wallet_id=wallet_id,
            to_wallet_id=None,
            from_goal_id=None,
            to_goal_id=None,
            from_category_id=None,
            to_category_id=expense.category_id,
            amount=amount,
            transaction_date=date,
            type="expense",
            comment=comment
        )
        transaction.create(db, obj_in=transaction_obj)
        return wallet

crud_wallet = CRUDWallet() 