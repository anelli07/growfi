"""set ON DELETE SET NULL for goal_id in transaction

Revision ID: ccd60aafd002
Revises: eb6f7990bfc4
Create Date: 2025-07-16 03:25:48.266278

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ccd60aafd002'
down_revision: Union[str, Sequence[str], None] = 'eb6f7990bfc4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Удаляем старые ограничения
    op.drop_constraint('transaction_to_goal_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_from_goal_id_fkey', 'transaction', type_='foreignkey')
    # Создаём новые с ON DELETE SET NULL
    op.create_foreign_key(
        'transaction_to_goal_id_fkey',
        'transaction', 'goal',
        ['to_goal_id'], ['id'],
        ondelete='SET NULL'
    )
    op.create_foreign_key(
        'transaction_from_goal_id_fkey',
        'transaction', 'goal',
        ['from_goal_id'], ['id'],
        ondelete='SET NULL'
    )


def downgrade() -> None:
    op.drop_constraint('transaction_to_goal_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_from_goal_id_fkey', 'transaction', type_='foreignkey')
    op.create_foreign_key(
        'transaction_to_goal_id_fkey',
        'transaction', 'goal',
        ['to_goal_id'], ['id']
    )
    op.create_foreign_key(
        'transaction_from_goal_id_fkey',
        'transaction', 'goal',
        ['from_goal_id'], ['id']
    )
