from typing import List, Tuple, Optional
from datetime import date
from sqlmodel import Session, select, func
from app.crud.base import CRUDBase
from app.models import Expense, User
from app.schemas.transaction import ExpenseCreate, ExpenseUpdate

class CRUDExpense(CRUDBase[Expense, ExpenseCreate, ExpenseUpdate]):
    def create_with_user(self, db: Session, *, obj_in: ExpenseCreate, user: User) -> Expense:
        db_obj = Expense(**obj_in.dict(), user_id=user.id)
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
    ) -> Tuple[List[Expense], int]:
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

expense = CRUDExpense(Expense) 