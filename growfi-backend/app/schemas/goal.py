from pydantic import BaseModel
from typing import Optional

class GoalBase(BaseModel):
    name: str
    target_amount: float

class GoalCreate(GoalBase):
    pass

class GoalUpdate(GoalBase):
    current_amount: Optional[float]

class Goal(GoalBase):
    id: int
    current_amount: float
    user_id: int

    class Config:
        orm_mode = True 