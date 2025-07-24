from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app import crud, models
from app.api import deps
from app.services.ai_service import ai_service
from app.crud import crud_wallet, category, expense, income
router = APIRouter()

class AIMessageRequest(BaseModel):
    message: str

class AIMessageResponse(BaseModel):
    type: str
    transaction: dict = None
    response: str
    success: bool = True

@router.post("/process-message", response_model=AIMessageResponse)
def process_ai_message(
    *,
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
    request: AIMessageRequest
) -> Any:
    """
    Обрабатывает сообщение пользователя через AI
    """
    try:
        # Получаем данные пользователя
        categories = crud_category.get_multi_by_user(db=db, user=current_user)
        wallets = crud_wallet.get_multi_by_user(db=db, user_id=current_user.id)
        
        user_data = {
            "categories": [{"id": c.id, "name": c.name, "type": c.type} for c in categories],
            "wallets": [{"id": w.id, "name": w.name} for w in wallets],
            "currency": "KZT"
        }
        
        # Обрабатываем сообщение через AI
        result = ai_service.process_message(request.message, user_data)
        
        # Если это транзакция, создаем её
        if result.get("type") == "transaction" and result.get("transaction"):
            transaction_data = result["transaction"]
            
            # Находим категорию
            category_obj = None
            if transaction_data.get("category"):
                category_obj = next((c for c in categories if c.name.lower() == transaction_data["category"].lower()), None)
            
            # Находим кошелек
            wallet = None
            if transaction_data.get("wallet"):
                wallet = next((w for w in wallets if w.name.lower() == transaction_data["wallet"].lower()), wallets[0] if wallets else None)
            else:
                wallet = wallets[0] if wallets else None
            
            if transaction_data["type"] == "expense":
                # Создаем расход
                expense_obj = crud_expense.create(
                    db=db,
                    obj_in=models.ExpenseCreate(
                        name=transaction_data.get("description", "Расход"),
                        amount=transaction_data["amount"],
                        category_id=category_obj.id if category_obj else None,
                        wallet_id=wallet.id if wallet else None,
                        user_id=current_user.id
                    )
                )
                result["transaction_id"] = expense_obj.id
                
            elif transaction_data["type"] == "income":
                # Создаем доход
                income_obj = crud_income.create(
                    db=db,
                    obj_in=models.IncomeCreate(
                        name=transaction_data.get("description", "Доход"),
                        amount=transaction_data["amount"],
                        category_id=category_obj.id if category_obj else None,
                        wallet_id=wallet.id if wallet else None,
                        user_id=current_user.id
                    )
                )
                result["transaction_id"] = income_obj.id
        
        return AIMessageResponse(
            type=result.get("type", "error"),
            transaction=result.get("transaction"),
            response=result.get("response", "Ошибка обработки"),
            success=result.get("type") != "error"
        )
        
    except Exception as e:
        return AIMessageResponse(
            type="error",
            response=f"Ошибка: {str(e)}",
            success=False
        )

@router.get("/analyze-expenses")
def analyze_expenses(
    *,
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
    period: str = "month"
) -> Any:
    """
    Анализирует расходы пользователя и дает рекомендации
    """
    try:
        # Получаем транзакции за период
        transactions = crud.transaction.get_multi_by_user(db=db, user=current_user)
        
        # Фильтруем по периоду (упрощенно)
        if period == "week":
            # Логика для недели
            pass
        elif period == "month":
            # Логика для месяца
            pass
        
        # Конвертируем в JSON для AI
        transactions_data = []
        for t in transactions:
            transactions_data.append({
                "id": t.id,
                "type": t.type,
                "amount": t.amount,
                "category": t.category.name if t.category else None,
                "description": t.name,
                "date": t.date.isoformat() if t.date else None
            })
        
        # Анализируем через AI
        analysis = ai_service.analyze_expenses(transactions_data, period)
        
        return {
            "analysis": analysis,
            "period": period,
            "transactions_count": len(transactions_data)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка анализа: {str(e)}") 