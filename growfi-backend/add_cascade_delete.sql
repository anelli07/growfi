-- Добавляем каскадное удаление для всех таблиц, связанных с пользователем
-- При удалении пользователя будут удалены все его данные

-- Принудительно удаляем существующие foreign key constraints
ALTER TABLE "category" DROP CONSTRAINT "category_user_id_fkey";
ALTER TABLE "expense" DROP CONSTRAINT "expense_category_id_fkey";
ALTER TABLE "expense" DROP CONSTRAINT "expense_user_id_fkey";
ALTER TABLE "expense" DROP CONSTRAINT "expense_wallet_id_fkey";
ALTER TABLE "goal" DROP CONSTRAINT "goal_user_id_fkey";
ALTER TABLE "income" DROP CONSTRAINT "income_category_id_fkey";
ALTER TABLE "income" DROP CONSTRAINT "income_user_id_fkey";
ALTER TABLE "income" DROP CONSTRAINT "income_wallet_id_fkey";
ALTER TABLE "transaction" DROP CONSTRAINT "transaction_from_category_id_fkey";
ALTER TABLE "transaction" DROP CONSTRAINT "transaction_from_goal_id_fkey";
ALTER TABLE "transaction" DROP CONSTRAINT "transaction_from_wallet_id_fkey";
ALTER TABLE "transaction" DROP CONSTRAINT "transaction_to_category_id_fkey";
ALTER TABLE "transaction" DROP CONSTRAINT "transaction_to_goal_id_fkey";
ALTER TABLE "transaction" DROP CONSTRAINT "transaction_to_wallet_id_fkey";
ALTER TABLE "transaction" DROP CONSTRAINT "transaction_user_id_fkey";
ALTER TABLE "wallet" DROP CONSTRAINT "wallet_user_id_fkey";

-- Добавляем внешние ключи с каскадным удалением для user_id
ALTER TABLE "category" ADD CONSTRAINT "category_user_id_fkey" 
    FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE "expense" ADD CONSTRAINT "expense_user_id_fkey" 
    FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE "goal" ADD CONSTRAINT "goal_user_id_fkey" 
    FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE "income" ADD CONSTRAINT "income_user_id_fkey" 
    FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE "transaction" ADD CONSTRAINT "transaction_user_id_fkey" 
    FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

ALTER TABLE "wallet" ADD CONSTRAINT "wallet_user_id_fkey" 
    FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

-- Добавляем каскадное удаление для связанных таблиц
ALTER TABLE "expense" ADD CONSTRAINT "expense_category_id_fkey" 
    FOREIGN KEY (category_id) REFERENCES "category"(id) ON DELETE CASCADE;

ALTER TABLE "income" ADD CONSTRAINT "income_category_id_fkey" 
    FOREIGN KEY (category_id) REFERENCES "category"(id) ON DELETE CASCADE;

-- Добавляем остальные constraints с каскадным удалением
ALTER TABLE "expense" ADD CONSTRAINT "expense_wallet_id_fkey" 
    FOREIGN KEY (wallet_id) REFERENCES "wallet"(id) ON DELETE CASCADE;

ALTER TABLE "income" ADD CONSTRAINT "income_wallet_id_fkey" 
    FOREIGN KEY (wallet_id) REFERENCES "wallet"(id) ON DELETE CASCADE;

ALTER TABLE "transaction" ADD CONSTRAINT "transaction_from_category_id_fkey" 
    FOREIGN KEY (from_category_id) REFERENCES "category"(id) ON DELETE CASCADE;

ALTER TABLE "transaction" ADD CONSTRAINT "transaction_from_goal_id_fkey" 
    FOREIGN KEY (from_goal_id) REFERENCES "goal"(id) ON DELETE CASCADE;

ALTER TABLE "transaction" ADD CONSTRAINT "transaction_from_wallet_id_fkey" 
    FOREIGN KEY (from_wallet_id) REFERENCES "wallet"(id) ON DELETE CASCADE;

ALTER TABLE "transaction" ADD CONSTRAINT "transaction_to_category_id_fkey" 
    FOREIGN KEY (to_category_id) REFERENCES "category"(id) ON DELETE CASCADE;

ALTER TABLE "transaction" ADD CONSTRAINT "transaction_to_goal_id_fkey" 
    FOREIGN KEY (to_goal_id) REFERENCES "goal"(id) ON DELETE CASCADE;

ALTER TABLE "transaction" ADD CONSTRAINT "transaction_to_wallet_id_fkey" 
    FOREIGN KEY (to_wallet_id) REFERENCES "wallet"(id) ON DELETE CASCADE; 