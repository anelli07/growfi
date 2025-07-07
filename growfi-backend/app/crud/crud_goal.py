from app.crud.base import CRUDBase
from app.models.goal import Goal
from app.schemas.goal import GoalCreate, GoalUpdate

class CRUDGoal(CRUDBase[Goal, GoalCreate, GoalUpdate]):
    def create_with_user(self, db, obj_in, user):
        db_obj = Goal(**obj_in.dict(), user_id=user.id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_multi_by_user(self, db, user, skip=0, limit=100):
        return db.query(Goal).filter(Goal.user_id == user.id).offset(skip).limit(limit).all()

goal = CRUDGoal(Goal) 