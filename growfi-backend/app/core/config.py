from typing import List, Optional
from pydantic import EmailStr
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Core settings
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str
    PROJECT_NAME: str = "GrowFi"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    REFRESH_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30  # 30 days

    # CORS settings
    BACKEND_CORS_ORIGINS: List[str] = ["*"]
    DATABASE_URL: str

    # Database settings
    POSTGRES_SERVER: str
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str
    SQLALCHEMY_DATABASE_URI: Optional[str] = None

    # Google Auth
    GOOGLE_CLIENT_ID: Optional[str] = None

    # Email settings
    MAIL_USERNAME: str
    MAIL_PASSWORD: str
    MAIL_FROM: EmailStr
    MAIL_PORT: int = 587
    MAIL_SERVER: str
    MAIL_FROM_NAME: str
    MAIL_STARTTLS: bool = True
    MAIL_SSL_TLS: bool = False
    EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS: int = 48
    EMAIL_TEMPLATES_DIR: str = "/app/templates/email"
    MAIL_CONSOLE: Optional[bool] = False

    class Config:
        case_sensitive = True
        env_file = ".env"


settings = Settings()

# Assemble database URI if not provided
if not settings.SQLALCHEMY_DATABASE_URI:
    settings.SQLALCHEMY_DATABASE_URI = (
        f"postgresql+psycopg2://{settings.POSTGRES_USER}:{settings.POSTGRES_PASSWORD}@"
        f"{settings.POSTGRES_SERVER}/{settings.POSTGRES_DB}"
    )
