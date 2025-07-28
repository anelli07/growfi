from app.crud.base import CRUDBase
from app.models.goal import Goal
from app.schemas.goal import GoalCreate, GoalUpdate

class CRUDGoal(CRUDBase[Goal, GoalCreate, GoalUpdate]):
    def create_with_user(self, db, obj_in, user):
        db_obj = Goal(
            name=obj_in.name,
            target_amount=obj_in.target_amount,
            current_amount=obj_in.current_amount,
            icon=obj_in.icon,
            color=obj_in.color,
            currency=obj_in.currency,
            user_id=user.id,
            plan_period=getattr(obj_in, 'plan_period', None),
            plan_amount=getattr(obj_in, 'plan_amount', None),
            reminder_period=getattr(obj_in, 'reminder_period', None),
            selected_weekday=getattr(obj_in, 'selected_weekday', None),
            selected_month_day=getattr(obj_in, 'selected_month_day', None),
            selected_time=getattr(obj_in, 'selected_time', None)
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_multi_by_user(self, db, user, skip=0, limit=100):
        return db.query(Goal).filter(Goal.user_id == user.id).offset(skip).limit(limit).all()

goal = CRUDGoal(Goal) 