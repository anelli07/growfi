"""add email verification code fields to user

Revision ID: add_email_verification_code
Revises: d2cc37980482
Create Date: 2025-06-20 12:00:00.000000
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'add_email_verification_code'
down_revision = 'd2cc37980482'
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('user', sa.Column('email_verification_code', sa.String(), nullable=True))
    op.add_column('user', sa.Column('email_verification_code_sent_at', sa.DateTime(), nullable=True))

def downgrade():
    op.drop_column('user', 'email_verification_code')
    op.drop_column('user', 'email_verification_code_sent_at') 