from typing import List
from pydantic import BaseModel


class CategoryExpense(BaseModel):
    category_name: str
    amount: float


class DashboardData(BaseModel):
    total_income: float
    total_expense: float
    balance: float
    expenses_by_category: List[CategoryExpense]
