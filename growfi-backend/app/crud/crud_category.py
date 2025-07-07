from typing import List
from sqlmodel import Session, select
from app.models.category import Category
from app.models.user import User
from app.schemas.category import CategoryCreate, CategoryUpdate
from app.crud.base import CRUDBase


class CRUDCategory(CRUDBase[Category, CategoryCreate, CategoryUpdate]):
    def create_with_user(
        self, db: Session, *, obj_in: CategoryCreate, user: User
    ) -> Category:
        db_obj = Category(name=obj_in.name, type=obj_in.type.value, user_id=user.id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_multi_by_user(
        self, db: Session, *, user: User, skip: int = 0, limit: int = 100
    ) -> List[Category]:
        statement = (
            select(Category)
            .where(Category.user_id == user.id)
            .offset(skip)
            .limit(limit)
        )
        return db.exec(statement).all()

    def update(
        self, db: Session, *, db_obj: Category, obj_in: CategoryUpdate
    ) -> Category:
        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.dict(exclude_unset=True)
        return super().update(db, db_obj=db_obj, obj_in=update_data)

    def remove(self, db: Session, *, id: int) -> Category:
        return super().remove(db, id=id)


category = CRUDCategory(Category)
