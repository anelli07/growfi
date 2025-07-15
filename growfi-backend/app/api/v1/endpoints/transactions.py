from fastapi import APIRouter, Depends, Request
from sqlmodel import Session
from app import models
from app.api import deps
from app.crud.crud_transaction import transaction
from app.schemas.transaction import TransactionRead
import inspect
import sys

router = APIRouter()

@router.get("/", response_model=list[dict])
def get_transactions(
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
):
    frame = inspect.currentframe()
    outer_frames = inspect.getouterframes(frame)
    # Попробуем получить request через стек (FastAPI не даёт напрямую)
    request = None
    for f in outer_frames:
        if 'request' in f.frame.f_locals:
            request = f.frame.f_locals['request']
            break
    print(f"[DEBUG] get_transactions: user={getattr(current_user, 'id', None)}, email={getattr(current_user, 'email', None)}")
    if request:
        print(f"[DEBUG] get_transactions: Authorization header = {request.headers.get('authorization')}")
    else:
        print("[DEBUG] get_transactions: request object not found in stack, не могу вывести токен")
    txs = transaction.get_multi_by_user(db, user_id=current_user.id)
    # Собираем id-шники для батч-запроса
    wallet_ids = set()
    category_ids = set()
    for tx in txs:
        if tx.from_wallet_id:
            wallet_ids.add(tx.from_wallet_id)
        if tx.to_wallet_id:
            wallet_ids.add(tx.to_wallet_id)
        if tx.from_category_id:
            category_ids.add(tx.from_category_id)
        if tx.to_category_id:
            category_ids.add(tx.to_category_id)
    # Получаем имена кошельков и категорий
    wallets = {w.id: w.name for w in db.query(models.Wallet).filter(models.Wallet.id.in_(wallet_ids)).all()}
    categories = {c.id: c.name for c in db.query(models.Category).filter(models.Category.id.in_(category_ids)).all()}
    result = []
    for tx in txs:
        # Логика: для дохода/расхода/цели определяем, что показывать как category и wallet
        if tx.type == "income":
            category = categories.get(tx.to_category_id) or categories.get(tx.from_category_id)
            wallet = wallets.get(tx.to_wallet_id) or wallets.get(tx.from_wallet_id)
        elif tx.type == "expense":
            category = categories.get(tx.from_category_id) or categories.get(tx.to_category_id)
            wallet = wallets.get(tx.from_wallet_id) or wallets.get(tx.to_wallet_id)
        elif tx.type == "goal":
            category = categories.get(tx.to_category_id) or categories.get(tx.from_category_id)
            wallet = wallets.get(tx.from_wallet_id) or wallets.get(tx.to_wallet_id)
        else:
            category = None
            wallet = None
        result.append({
            "id": tx.id,
            "date": tx.transaction_date.strftime("%Y-%m-%dT%H:%M:%SZ") if tx.transaction_date else None,
            "category": category,
            "amount": tx.amount,
            "type": tx.type,
            "note": tx.comment,
            "wallet": wallet,
        })
    return result

# Явный endpoint без редиректа
@router.get("", response_model=list[dict], include_in_schema=False)
def get_transactions_noslash(
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_active_user),
):
    return get_transactions(db=db, current_user=current_user) 