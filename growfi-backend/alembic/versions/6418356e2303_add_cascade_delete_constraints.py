"""add_cascade_delete_constraints

Revision ID: 6418356e2303
Revises: c6aa3a554c7e
Create Date: 2025-07-18 19:08:00.979930

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6418356e2303'
down_revision: Union[str, Sequence[str], None] = 'c6aa3a554c7e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Удаляем существующие foreign key constraints
    op.drop_constraint('category_user_id_fkey', 'category', type_='foreignkey')
    op.drop_constraint('expense_category_id_fkey', 'expense', type_='foreignkey')
    op.drop_constraint('expense_user_id_fkey', 'expense', type_='foreignkey')
    op.drop_constraint('expense_wallet_id_fkey', 'expense', type_='foreignkey')
    op.drop_constraint('goal_user_id_fkey', 'goal', type_='foreignkey')
    op.drop_constraint('income_category_id_fkey', 'income', type_='foreignkey')
    op.drop_constraint('income_user_id_fkey', 'income', type_='foreignkey')
    op.drop_constraint('income_wallet_id_fkey', 'income', type_='foreignkey')
    op.drop_constraint('transaction_from_category_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_from_goal_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_from_wallet_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_category_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_goal_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_wallet_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_user_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('wallet_user_id_fkey', 'wallet', type_='foreignkey')

    # Добавляем новые constraints с каскадным удалением
    op.create_foreign_key('category_user_id_fkey', 'category', 'user', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('expense_category_id_fkey', 'expense', 'category', ['category_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('expense_user_id_fkey', 'expense', 'user', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('expense_wallet_id_fkey', 'expense', 'wallet', ['wallet_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('goal_user_id_fkey', 'goal', 'user', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('income_category_id_fkey', 'income', 'category', ['category_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('income_user_id_fkey', 'income', 'user', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('income_wallet_id_fkey', 'income', 'wallet', ['wallet_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('transaction_from_category_id_fkey', 'transaction', 'category', ['from_category_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('transaction_from_goal_id_fkey', 'transaction', 'goal', ['from_goal_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('transaction_from_wallet_id_fkey', 'transaction', 'wallet', ['from_wallet_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('transaction_to_category_id_fkey', 'transaction', 'category', ['to_category_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('transaction_to_goal_id_fkey', 'transaction', 'goal', ['to_goal_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('transaction_to_wallet_id_fkey', 'transaction', 'wallet', ['to_wallet_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('transaction_user_id_fkey', 'transaction', 'user', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('wallet_user_id_fkey', 'wallet', 'user', ['user_id'], ['id'], ondelete='CASCADE')


def downgrade() -> None:
    """Downgrade schema."""
    # Удаляем constraints с каскадным удалением
    op.drop_constraint('category_user_id_fkey', 'category', type_='foreignkey')
    op.drop_constraint('expense_category_id_fkey', 'expense', type_='foreignkey')
    op.drop_constraint('expense_user_id_fkey', 'expense', type_='foreignkey')
    op.drop_constraint('expense_wallet_id_fkey', 'expense', type_='foreignkey')
    op.drop_constraint('goal_user_id_fkey', 'goal', type_='foreignkey')
    op.drop_constraint('income_category_id_fkey', 'income', type_='foreignkey')
    op.drop_constraint('income_user_id_fkey', 'income', type_='foreignkey')
    op.drop_constraint('income_wallet_id_fkey', 'income', type_='foreignkey')
    op.drop_constraint('transaction_from_category_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_from_goal_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_from_wallet_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_category_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_goal_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_to_wallet_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('transaction_user_id_fkey', 'transaction', type_='foreignkey')
    op.drop_constraint('wallet_user_id_fkey', 'wallet', type_='foreignkey')

    # Восстанавливаем старые constraints без каскадного удаления
    op.create_foreign_key('category_user_id_fkey', 'category', 'user', ['user_id'], ['id'])
    op.create_foreign_key('expense_category_id_fkey', 'expense', 'category', ['category_id'], ['id'])
    op.create_foreign_key('expense_user_id_fkey', 'expense', 'user', ['user_id'], ['id'])
    op.create_foreign_key('expense_wallet_id_fkey', 'expense', 'wallet', ['wallet_id'], ['id'])
    op.create_foreign_key('goal_user_id_fkey', 'goal', 'user', ['user_id'], ['id'])
    op.create_foreign_key('income_category_id_fkey', 'income', 'category', ['category_id'], ['id'])
    op.create_foreign_key('income_user_id_fkey', 'income', 'user', ['user_id'], ['id'])
    op.create_foreign_key('income_wallet_id_fkey', 'income', 'wallet', ['wallet_id'], ['id'])
    op.create_foreign_key('transaction_from_category_id_fkey', 'transaction', 'category', ['from_category_id'], ['id'])
    op.create_foreign_key('transaction_from_goal_id_fkey', 'transaction', 'goal', ['from_goal_id'], ['id'])
    op.create_foreign_key('transaction_from_wallet_id_fkey', 'transaction', 'wallet', ['from_wallet_id'], ['id'])
    op.create_foreign_key('transaction_to_category_id_fkey', 'transaction', 'category', ['to_category_id'], ['id'])
    op.create_foreign_key('transaction_to_goal_id_fkey', 'transaction', 'goal', ['to_goal_id'], ['id'])
    op.create_foreign_key('transaction_to_wallet_id_fkey', 'transaction', 'wallet', ['to_wallet_id'], ['id'])
    op.create_foreign_key('transaction_user_id_fkey', 'transaction', 'user', ['user_id'], ['id'])
    op.create_foreign_key('wallet_user_id_fkey', 'wallet', 'user', ['user_id'], ['id'])
