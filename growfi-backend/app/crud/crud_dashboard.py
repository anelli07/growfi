from datetime import date
from sqlalchemy import func
from sqlmodel import Session, select

from app.models import Income, Expense, User, Category
from app.schemas.dashboard import DashboardData, CategoryExpense
from app.models.transaction import Transaction


def get_dashboard_data(
    db: Session, *, user: User, start_date: date, end_date: date
) -> DashboardData:

    # Total Income
    total_income_query = select(func.sum(Transaction.amount)).where(
        Transaction.user_id == user.id,
        Transaction.type == "income",
        Transaction.amount > 0,
        Transaction.transaction_date >= start_date,
        Transaction.transaction_date <= end_date,
    )
    total_income = db.exec(total_income_query).one_or_none() or 0.0

    # Total Expense
    total_expense_query = select(func.sum(Transaction.amount)).where(
        Transaction.user_id == user.id,
        Transaction.type == "expense",
        Transaction.amount > 0,
        Transaction.transaction_date >= start_date,
        Transaction.transaction_date <= end_date,
    )
    total_expense = db.exec(total_expense_query).one_or_none() or 0.0

    # Expenses by Category
    # (если нужно, можно добавить join с Category по to_category_id)
    expenses_by_cat_query = (
        select(Category.name, func.sum(Transaction.amount))
        .join(Category, Transaction.to_category_id == Category.id)
        .where(
            Transaction.user_id == user.id,
            Transaction.type == "expense",
            Transaction.amount > 0,
            Transaction.transaction_date >= start_date,
            Transaction.transaction_date <= end_date,
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
