from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from typing import List
from app import crud, models, schemas
from app.models.wallet import Wallet
from app.api import deps
from app.schemas.wallet import WalletAssignGoal, WalletAssignExpense

router = APIRouter()

@router.get("/", response_model=List[schemas.Wallet])
def read_wallets(db: Session = Depends(deps.get_db), current_user: models.User = Depends(deps.get_current_active_user)):
    return crud.crud_wallet.get_multi_by_user(db=db, user_id=current_user.id)

@router.post("/", response_model=schemas.Wallet)
def create_wallet(wallet_in: schemas.WalletCreate, db: Session = Depends(deps.get_db), current_user: models.User = Depends(deps.get_current_active_user)):
    return crud.crud_wallet.create_with_user(db=db, obj_in=wallet_in, user_id=current_user.id)

@router.put("/{id}", response_model=schemas.Wallet)
def update_wallet(id: int, wallet_in: schemas.WalletUpdate, db: Session = Depends(deps.get_db), current_user: models.User = Depends(deps.get_current_active_user)):
    db_obj = db.get(Wallet, id)
    if not db_obj or db_obj.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Wallet not found")
    return crud.crud_wallet.update(db=db, db_obj=db_obj, obj_in=wallet_in)

@router.delete("/{id}", response_model=schemas.Wallet)
def delete_wallet(id: int, db: Session = Depends(deps.get_db), current_user: models.User = Depends(deps.get_current_active_user)):
    db_obj = db.get(Wallet, id)
    if not db_obj or db_obj.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Wallet not found")
    return crud.crud_wallet.remove(db=db, id=id)

@router.patch("/{id}/assign-goal", response_model=schemas.Wallet)
def assign_goal(
    *,
    db: Session = Depends(deps.get_db),
    id: int,
    assign_in: WalletAssignGoal,
    current_user: models.User = Depends(deps.get_current_active_user),
):
    wallet = db.get(Wallet, id)
    if not wallet or wallet.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Wallet not found")
    # Реализовать crud.crud_wallet.assign_goal(...)
    return wallet

@router.patch("/{id}/assign-expense", response_model=schemas.Wallet)
def assign_expense(
    *,
    db: Session = Depends(deps.get_db),
    id: int,
    assign_in: WalletAssignExpense,
    current_user: models.User = Depends(deps.get_current_active_user),
):
    wallet = db.get(Wallet, id)
    if not wallet or wallet.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Wallet not found")
    # Реализовать crud.crud_wallet.assign_expense(...)
    return wallet 