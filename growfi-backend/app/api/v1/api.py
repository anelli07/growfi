from fastapi import APIRouter

# from .endpoints import users, auth, ...

from app.api.v1.endpoints import auth, user, category, income, expense, dashboard, goal, wallet, transactions
from app.api.v1.endpoints.expense import main_router as transactions_router

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(user.router, prefix="/users", tags=["users"])
api_router.include_router(category.router, prefix="/categories", tags=["categories"])
api_router.include_router(income.router, prefix="/incomes", tags=["incomes"])
api_router.include_router(expense.router, prefix="/expenses", tags=["expenses"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(goal.router, prefix="/goals", tags=["goals"])
api_router.include_router(wallet.router, prefix="/wallet", tags=["wallet"])
api_router.include_router(transactions.router, prefix="/transactions", tags=["transactions"])
# api_router.include_router(users.router, prefix="/users", tags=["users"])
