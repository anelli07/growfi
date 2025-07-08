from typing import List, Optional
from sqlmodel import Session, select
from app.models.wallet import Wallet
from app.schemas.wallet import WalletCreate, WalletUpdate

class CRUDWallet:
    def get_multi_by_user(self, db: Session, user_id: int) -> List[Wallet]:
        return db.exec(select(Wallet).where(Wallet.user_id == user_id)).all()

    def create_with_user(self, db: Session, obj_in: WalletCreate, user_id: int) -> Wallet:
        db_obj = Wallet(**obj_in.dict(), user_id=user_id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def update(self, db: Session, db_obj: Wallet, obj_in: WalletUpdate) -> Wallet:
        obj_data = obj_in.dict(exclude_unset=True)
        for field, value in obj_data.items():
            setattr(db_obj, field, value)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def remove(self, db: Session, id: int) -> Optional[Wallet]:
        obj = db.get(Wallet, id)
        if obj:
            db.delete(obj)
            db.commit()
        return obj

crud_wallet = CRUDWallet() 