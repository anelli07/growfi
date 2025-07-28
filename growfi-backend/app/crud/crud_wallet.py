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
            try:
                # НЕ удаляем транзакции - они должны сохраняться как история
                # Просто обнуляем wallet_id в транзакциях, связанных с этим кошельком
                from sqlalchemy import text
                
                db.execute(text('UPDATE transaction SET from_wallet_id = NULL WHERE from_wallet_id = :wallet_id'), 
                          {'wallet_id': id})
                db.execute(text('UPDATE transaction SET to_wallet_id = NULL WHERE to_wallet_id = :wallet_id'), 
                          {'wallet_id': id})
                
                # НЕ удаляем доходы и расходы - они могут быть связаны с другими кошельками
                # Просто обнуляем wallet_id в доходах и расходах, связанных с этим кошельком
                db.execute(text('UPDATE income SET wallet_id = NULL WHERE wallet_id = :wallet_id'), 
                          {'wallet_id': id})
                db.execute(text('UPDATE expense SET wallet_id = NULL WHERE wallet_id = :wallet_id'), 
                          {'wallet_id': id})
                
                # Теперь удаляем сам кошелек
                db.delete(obj)
                db.commit()
                
            except Exception as e:
                db.rollback()
                print(f"Error deleting wallet {id}: {str(e)}")
                raise e
        return obj

    def assign_goal(self, db: Session, *, wallet_id: int, goal_id: int, amount: float, date: str, comment: str = None):
        wallet = db.get(Wallet, wallet_id)
        goal = db.get(Goal, goal_id)
        
        if not wallet:
            raise ValueError("Wallet not found")
        if not goal:
            raise ValueError("Goal not found")
        
        # Проверяем базовые условия
        if amount <= 0:
            raise ValueError("Amount must be positive")
        if wallet.balance < amount:
            raise ValueError("Not enough funds in wallet")
        
        # Проверяем, не достигнута ли уже цель
        if goal.current_amount >= goal.target_amount:
            raise ValueError("Goal is already completed")
        
        # Проверяем, не превысит ли сумма целевую
        remaining_amount = goal.target_amount - goal.current_amount
        if amount > remaining_amount:
            raise ValueError(f"Amount exceeds remaining goal amount. Max available: {remaining_amount}")
        
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
            comment=comment,
            goal_name=goal.name,
            name=goal.name,
            icon=goal.icon,
            color=goal.color,
            wallet_name=wallet.name
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
            comment=comment,
            name=expense.name,
            icon=expense.icon,
            color=expense.color,
            wallet_name=wallet.name
        )
        transaction.create(db, obj_in=transaction_obj)
        return wallet

crud_wallet = CRUDWallet() 