from datetime import date
from sqlalchemy import func
from sqlmodel import Session, select

from app.models import Income, Expense, User, Category
from app.schemas.dashboard import DashboardData, CategoryExpense


def get_dashboard_data(
    db: Session, *, user: User, start_date: date, end_date: date
) -> DashboardData:

    # Total Income
    total_income_query = select(func.sum(Income.amount)).where(
        Income.user_id == user.id,
        Income.transaction_date >= start_date,
        Income.transaction_date <= end_date,
    )
    total_income = db.exec(total_income_query).one_or_none() or 0.0

    # Total Expense
    total_expense_query = select(func.sum(Expense.amount)).where(
        Expense.user_id == user.id,
        Expense.transaction_date >= start_date,
        Expense.transaction_date <= end_date,
    )
    total_expense = db.exec(total_expense_query).one_or_none() or 0.0

    # Expenses by Category
    expenses_by_cat_query = (
        select(Category.name, func.sum(Expense.amount))
        .join(Category)
        .where(
            Expense.user_id == user.id,
            Expense.transaction_date >= start_date,
            Expense.transaction_date <= end_date,
        )
        .group_by(Category.name)
    )
    expenses_by_cat_result = db.exec(expenses_by_cat_query).all()

    expenses_by_category = [
        CategoryExpense(category_name=name, amount=amount)
        for name, amount in expenses_by_cat_result
    ]

    # Balance
    balance = total_income - total_expense

    return DashboardData(
        total_income=total_income,
        total_expense=total_expense,
        balance=balance,
        expenses_by_category=expenses_by_category,
    )
