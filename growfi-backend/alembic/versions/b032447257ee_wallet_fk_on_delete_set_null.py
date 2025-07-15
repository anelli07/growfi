"""wallet fk on delete set null

Revision ID: b032447257ee
Revises: 56e8a42aee3e
Create Date: 2025-07-15 09:52:03.272440

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b032447257ee'
down_revision: Union[str, Sequence[str], None] = '56e8a42aee3e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    # Удаляем старые ограничения
    op.drop_constraint('transaction_from_wallet_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_wallet_id_fkey', 'transaction', type_='foreignkey')
    # Добавляем новые с ON DELETE SET NULL
    op.create_foreign_key(
        'transaction_from_wallet_id_fkey',
        'transaction', 'wallet',
        ['from_wallet_id'], ['id'],
        ondelete='SET NULL'
    )
    op.create_foreign_key(
        'transaction_to_wallet_id_fkey',
        'transaction', 'wallet',
        ['to_wallet_id'], ['id'],
        ondelete='SET NULL'
    )

def downgrade():
    op.drop_constraint('transaction_from_wallet_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_wallet_id_fkey', 'transaction', type_='foreignkey')
    op.create_foreign_key(
        'transaction_from_wallet_id_fkey',
        'transaction', 'wallet',
        ['from_wallet_id'], ['id']
    )
    op.create_foreign_key(
        'transaction_to_wallet_id_fkey',
        'transaction', 'wallet',
        ['to_wallet_id'], ['id']
    )