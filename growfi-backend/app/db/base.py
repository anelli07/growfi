from sqlmodel import SQLModel

# This will be the base class for all of our models.
# When Alembic generates migrations, it will look at all classes
# that inherit from this Base and find any changes.
Base = SQLModel

# Import all the models, so that Base has them before being
# imported by Alembic
from app.models.user import User  # noqa
from app.models.category import Category  # noqa
from app.models.transaction import Income, Expense  # noqa
