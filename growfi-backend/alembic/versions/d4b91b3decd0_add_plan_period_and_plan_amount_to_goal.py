"""add_plan_period_and_plan_amount_to_goal

Revision ID: d4b91b3decd0
Revises: 48d7f741f033
Create Date: 2025-07-28 09:57:50.636238

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd4b91b3decd0'
down_revision: Union[str, Sequence[str], None] = '48d7f741f033'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Добавляем поля для планирования накопления
    op.add_column('goal', sa.Column('plan_period', sa.String(), nullable=True))
    op.add_column('goal', sa.Column('plan_amount', sa.Float(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    # Удаляем поля для планирования накопления
    op.drop_column('goal', 'plan_amount')
    op.drop_column('goal', 'plan_period')
