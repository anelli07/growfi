from pydantic import BaseModel
from typing import Optional

class GoalBase(BaseModel):
    name: str
    target_amount: float
    currency: str
    icon: str
    color: str

class GoalCreate(GoalBase):
    pass

class GoalUpdate(BaseModel):
    name: Optional[str] = None
    target_amount: Optional[float] = None
    icon: Optional[str] = None
    color: Optional[str] = None

class Goal(GoalBase):
    id: int
    current_amount: float
    user_id: int

    class Config:
        orm_mode = True 