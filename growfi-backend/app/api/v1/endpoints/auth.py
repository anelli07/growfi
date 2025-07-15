from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.responses import JSONResponse
from sqlmodel import Session
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from pydantic import BaseModel, EmailStr
from datetime import date

from app import crud, schemas
from app.api import deps
from app.core import security
from app.core.config import settings
from app.schemas.token import GoogleToken
from app.services.email_service import send_verification_code_email
from app.models.category import CategoryType
from app.schemas.wallet import WalletCreate
from app.schemas.category import CategoryCreate
from app.schemas.transaction import IncomeCreate, ExpenseCreate

router = APIRouter()


@router.post("/register", response_model=schemas.User)
async def register_user(
    *,
    db: Session = Depends(deps.get_db),
    user_in: schemas.UserCreate,
) -> Any:
    """
    Create new user and send verification code.
    """
    user = crud.user.get_by_email(db, email=user_in.email)
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )
    user = crud.user.create(db, obj_in=user_in)

    # ДЕФОЛТНЫЕ КОШЕЛЬКИ
    wallet1 = crud.crud_wallet.create_with_user(db, WalletCreate(name="Карта", balance=0, icon_name="card", color_hex="#4F8A8B", currency="KZT"), user.id)
    wallet2 = crud.crud_wallet.create_with_user(db, WalletCreate(name="Наличные", balance=0, icon_name="cash", color_hex="#F9B208", currency="KZT"), user.id)

    # ДЕФОЛТНЫЕ КАТЕГОРИИ
    cat_income1 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Зарплата", type=CategoryType.INCOME), user=user)
    cat_expense1 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Еда", type=CategoryType.EXPENSE), user=user)
    cat_expense2 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Транспорт", type=CategoryType.EXPENSE), user=user)
    cat_expense3 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Продукты", type=CategoryType.EXPENSE), user=user)
    cat_expense4 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Развлечения", type=CategoryType.EXPENSE), user=user)
    cat_expense5 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Здоровье", type=CategoryType.EXPENSE), user=user)
    cat_expense6 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Связь", type=CategoryType.EXPENSE), user=user)
    cat_expense7 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Путешествия", type=CategoryType.EXPENSE), user=user)
    cat_expense8 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Одежда", type=CategoryType.EXPENSE), user=user)
    cat_expense9 = crud.category.create_with_user(db, obj_in=CategoryCreate(name="Красота", type=CategoryType.EXPENSE), user=user)
    


    # ДЕФОЛТНЫЕ ДОХОДЫ
    crud.income.create_with_user(db, obj_in=IncomeCreate(
        name="Зарплата",
        icon="dollarsign.circle.fill",
        color="#00FF00",
        amount=0,
        transaction_date=date.today(),
        category_id=cat_income1.id
    ), user=user)

    # ДЕФОЛТНЫЕ РАСХОДЫ
    expense_templates = [
        ("Еда", "cart.fill", "#FF0000", cat_expense1.id),
        ("Транспорт", "car.fill", "#00FF00", cat_expense2.id),
        ("Продукты", "cart.fill", "#00FF00", cat_expense3.id),
        ("Развлечения", "gamecontroller.fill", "#00FF00", cat_expense4.id),
        ("Здоровье", "cross.case.fill", "#00FF00", cat_expense5.id),
        ("Связь", "phone.fill", "#00FF00", cat_expense6.id),
        ("Путешествия", "airplane", "#00FF00", cat_expense7.id),
        ("Одежда", "tshirt.fill", "#00FF00", cat_expense8.id),
        ("Красота", "scissors", "#00FF00", cat_expense9.id),
    ]
    for name, icon, color, category_id in expense_templates:
        crud.expense.create_with_user(db, obj_in=ExpenseCreate(
            name=name,
            icon=icon,
            color=color,
            amount=0,
            transaction_date=date.today(),
            category_id=category_id,
            wallet_id=wallet1.id
        ), user=user)

    await send_verification_code_email(
        email_to=user.email,
        full_name=user.full_name or user.email,
        code=user.email_verification_code,
    )
    return user


@router.post("/login", response_model=schemas.Token)
def login(
    db: Session = Depends(deps.get_db), form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """
    Get an access token for a user.
    """
    user = crud.user.authenticate(
        db, email=form_data.username, password=form_data.password
    )
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    elif not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    elif not user.is_email_verified:
        raise HTTPException(status_code=400, detail="Email не подтверждён")

    return {
        "access_token": security.create_access_token(user.id),
        "refresh_token": security.create_refresh_token(user.id),
        "token_type": "bearer",
    }


@router.post("/google", response_model=schemas.Token)
def auth_google(
    *, db: Session = Depends(deps.get_db), google_token: GoogleToken
) -> Any:
    """
    Authenticate with Google.
    """
    try:
        id_info = id_token.verify_oauth2_token(
            google_token.token, google_requests.Request(), settings.GOOGLE_CLIENT_ID
        )
        email = id_info["email"]
        google_id = id_info["sub"]
        full_name = id_info.get("name")
    except ValueError:
        raise HTTPException(
            status_code=403, detail="Could not validate Google credentials"
        )

    user = crud.user.get_by_google_id(db, google_id=google_id)
    if not user:
        user = crud.user.get_by_email(db, email=email)
        if user:
            raise HTTPException(
                status_code=400,
                detail="A user with this email already exists. Please log in with your password to link your Google account.",
            )
        user = crud.user.create_with_google(
            db, full_name=full_name, email=email, google_id=google_id
        )

    return {
        "access_token": security.create_access_token(user.id),
        "refresh_token": security.create_refresh_token(user.id),
        "token_type": "bearer",
    }


class EmailCodeVerifyRequest(BaseModel):
    email: EmailStr
    code: str


@router.post("/verify-code")
def verify_code(
    data: EmailCodeVerifyRequest,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Verify user's email by code.
    """
    ok = crud.user.verify_email_code(db, email=data.email, code=data.code)
    if not ok:
        raise HTTPException(status_code=400, detail="Неверный или истёкший код")
    return {"message": "Email подтверждён"}


class ResendCodeRequest(BaseModel):
    email: EmailStr


@router.post("/resend-code")
async def resend_code(
    data: ResendCodeRequest,
    db: Session = Depends(deps.get_db),
) -> Any:
    user = crud.user.get_by_email(db, email=data.email)
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    code = crud.user.resend_verification_code(db, email=data.email)
    await send_verification_code_email(
        email_to=user.email,
        full_name=user.full_name or user.email,
        code=code,
    )
    return {"message": "Код отправлен повторно"}


class TokenRefreshRequest(BaseModel):
    refresh_token: str

@router.post("/refresh", response_model=schemas.Token)
def refresh_token(
    *,
    db: Session = Depends(deps.get_db),
    data: TokenRefreshRequest
) -> Any:
    """
    Обновить access_token по refresh_token
    """
    user = db.query(crud.user.model).filter_by(refresh_token=data.refresh_token).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return {
        "access_token": security.create_access_token(user.id),
        "refresh_token": user.refresh_token,
        "token_type": "bearer",
    }

class LogoutRequest(BaseModel):
    refresh_token: str

@router.post("/logout")
def logout(
    *,
    db: Session = Depends(deps.get_db),
    data: LogoutRequest
) -> Any:
    """
    Logout пользователя (инвалидировать refresh_token)
    """
    user = db.query(crud.user.model).filter_by(refresh_token=data.refresh_token).first()
    if not user:
        return JSONResponse(status_code=status.HTTP_200_OK, content={"message": "Already logged out"})
    user.refresh_token = None
    db.add(user)
    db.commit()
    return {"message": "Logged out"}
