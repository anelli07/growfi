from fastapi import APIRouter, Depends, Request, HTTPException
from sqlmodel import Session
from app import models
from app.api import deps
from app.crud.crud_transaction import transaction
from app.schemas.transaction import TransactionRead
import inspect
import sys

router = APIRouter()

@router.delete("/{transaction_id}")
def delete_transaction(
    transaction_id: int,
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
):
    """
    Удалить транзакцию по ID
    """
    # Получаем транзакцию
    tx = transaction.get(db=db, id=transaction_id)
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    # Проверяем, что транзакция принадлежит текущему пользователю
    if tx.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    try:
        # Удаляем транзакцию
        transaction.remove(db=db, id=transaction_id)
        return {"message": "Transaction deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete transaction: {str(e)}")

@router.get("/", response_model=list[dict])
def get_transactions(
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
):
    txs = transaction.get_multi_by_user(db, user_id=current_user.id)
    # Собираем id-шники для батч-запроса
    wallet_ids = set()
    income_ids = set()
    expense_ids = set()
    goal_ids = set()
    for tx in txs:
        if tx.from_wallet_id:
            wallet_ids.add(tx.from_wallet_id)
        if tx.to_wallet_id:
            wallet_ids.add(tx.to_wallet_id)
        if tx.type == "income" and tx.to_category_id:
            income_ids.add(tx.to_category_id)
        if tx.type == "expense" and tx.to_category_id:
            expense_ids.add(tx.to_category_id)
        if tx.type == "goal_transfer" and tx.to_goal_id:
            goal_ids.add(tx.to_goal_id)
    # Получаем объекты
    wallets = {w.id: w for w in db.query(models.Wallet).filter(models.Wallet.id.in_(wallet_ids)).all()}
    incomes = {i.category_id: i for i in db.query(models.Income).filter(models.Income.category_id.in_(income_ids)).all()}
    expenses = {e.category_id: e for e in db.query(models.Expense).filter(models.Expense.category_id.in_(expense_ids)).all()}
    goals = {g.id: g for g in db.query(models.Goal).filter(models.Goal.id.in_(goal_ids)).all()}
    result = []
    for tx in txs:
        # Доход
        if tx.type == "income":
            income = incomes.get(tx.to_category_id)
            wallet = wallets.get(tx.to_wallet_id)
            result.append({
                "id": tx.id,
                "date": tx.transaction_date.strftime("%Y-%m-%dT%H:%M:%SZ") if tx.transaction_date else None,
                "type": tx.type,
                "amount": tx.amount,
                "note": tx.comment,
                "title": tx.name or (income.name if income else "Удалено"),
                "icon": tx.icon or (income.icon if income else "dollarsign.circle.fill"),
                "color": tx.color or (income.color if income else "#00FF00"),
                "wallet_name": tx.wallet_name if tx.wallet_name else (wallet.name if wallet else "Удалено"),
                "wallet_icon": wallet.icon_name if wallet else "creditcard",
                "wallet_color": wallet.color_hex if wallet else "#CCCCCC",
            })
        # Расход
        elif tx.type == "expense":
            expense = expenses.get(tx.to_category_id)
            wallet = wallets.get(tx.from_wallet_id)
            result.append({
                "id": tx.id,
                "date": tx.transaction_date.strftime("%Y-%m-%dT%H:%M:%SZ") if tx.transaction_date else None,
                "type": tx.type,
                "amount": tx.amount,
                "note": tx.comment,
                "title": tx.name or (expense.name if expense else "Удалено"),
                "icon": tx.icon or (expense.icon if expense else "cart.fill"),
                "color": tx.color or (expense.color if expense else "#FF0000"),
                "wallet_name": tx.wallet_name if tx.wallet_name else (wallet.name if wallet else "Удалено"),
                "wallet_icon": wallet.icon_name if wallet else "creditcard",
                "wallet_color": wallet.color_hex if wallet else "#CCCCCC",
            })
        # Цель
        elif tx.type == "goal_transfer":
            goal = goals.get(tx.to_goal_id)
            wallet = wallets.get(tx.from_wallet_id)
            result.append({
                "id": tx.id,
                "date": tx.transaction_date.strftime("%Y-%m-%dT%H:%M:%SZ") if tx.transaction_date else None,
                "type": tx.type,
                "amount": tx.amount,
                "note": tx.comment,
                "title": tx.goal_name if tx.goal_name else (goal.name if goal else "Удалено"),
                "icon": tx.icon or (goal.icon if goal else "leaf.circle.fill"),
                "color": tx.color or (goal.color if goal else "#00FF00"),
                "wallet_name": tx.wallet_name if tx.wallet_name else (wallet.name if wallet else "Удалено"),
                "wallet_icon": wallet.icon_name if wallet else "creditcard",
                "wallet_color": wallet.color_hex if wallet else "#CCCCCC",
                "goal_id": tx.to_goal_id,
            })
        # Остальные типы (wallet_transfer и т.д.) можно добавить по аналогии
    return result

# Явный endpoint без редиректа
@router.get("", response_model=list[dict], include_in_schema=False)
def get_transactions_noslash(
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
):
    return get_transactions(db=db, current_user=current_user) 