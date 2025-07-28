from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class GoalBase(BaseModel):
    name: str
    target_amount: float
    currency: str
    icon: str
    color: str
    # Новые поля для планирования накопления
    plan_period: Optional[str] = None
    plan_amount: Optional[float] = None
    # Новые поля для уведомлений
    reminder_period: Optional[str] = None
    selected_weekday: Optional[int] = None
    selected_month_day: Optional[int] = None
    selected_time: Optional[str] = None

class GoalCreate(GoalBase):
    current_amount: float = 0

class GoalUpdate(BaseModel):
    name: Optional[str] = None
    target_amount: Optional[float] = None
    current_amount: Optional[float] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    # Новые поля для планирования накопления
    plan_period: Optional[str] = None
    plan_amount: Optional[float] = None
    # Новые поля для уведомлений
    reminder_period: Optional[str] = None
    selected_weekday: Optional[int] = None
    selected_month_day: Optional[int] = None
    selected_time: Optional[str] = None

class Goal(GoalBase):
    id: int
    current_amount: float
    user_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True) 