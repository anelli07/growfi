"""set ondelete cascade for goal in transaction

Revision ID: c9ba08d33fd8
Revises: 50f972f85e70
Create Date: 2025-07-22 13:03:24.773676

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c9ba08d33fd8'
down_revision: Union[str, Sequence[str], None] = '50f972f85e70'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_constraint('transaction_from_goal_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_goal_id_fkey', 'transaction', type_='foreignkey')
    op.create_foreign_key(
        'transaction_from_goal_id_fkey',
        'transaction', 'goal',
        ['from_goal_id'], ['id'],
        ondelete='CASCADE'
    )
    op.create_foreign_key(
        'transaction_to_goal_id_fkey',
        'transaction', 'goal',
        ['to_goal_id'], ['id'],
        ondelete='CASCADE'
    )


def downgrade() -> None:
    op.drop_constraint('transaction_from_goal_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_goal_id_fkey', 'transaction', type_='foreignkey')
    op.create_foreign_key(
        'transaction_from_goal_id_fkey',
        'transaction', 'goal',
        ['from_goal_id'], ['id']
    )
    op.create_foreign_key(
        'transaction_to_goal_id_fkey',
        'transaction', 'goal',
        ['to_goal_id'], ['id']
    )
