import os
import json
from typing import Dict, Any, Optional
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential
from app.models.transaction import Transaction, Income, Expense
from app.models.category import Category
from app.models.wallet import Wallet
from datetime import datetime
from app.crud import crud_wallet, crud_category, crud_expense, crud_income

class AIService:
    def __init__(self):
        self.client = AzureOpenAI(
            api_key=os.getenv("AZURE_OPENAI_API_KEY"),
            api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-12-01-preview"),
            azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
        )
        self.model = os.getenv("AZURE_OPENAI_MODEL", "gpt-35-turbo")
    
    def process_message(self, message: str, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Обрабатывает сообщение пользователя и возвращает структурированные данные
        """
        system_prompt = """
        Ты финансовый помощник. Анализируй сообщения пользователя и извлекай информацию о транзакциях.
        
        Возможные типы транзакций:
        - expense: расходы (покупки, услуги)
        - income: доходы (зарплата, подарки)
        - transfer: переводы между кошельками
        
        Для каждой транзакции определи:
        - type: тип транзакции
        - amount: сумма (только число)
        - category: категория (еда, транспорт, зарплата, etc.)
        - description: описание
        - wallet: кошелек (если указан)
        
        Если это не транзакция, но финансовый вопрос - отвечай как консультант.
        
        Возвращай JSON в формате:
        {
            "type": "transaction|question|analysis",
            "transaction": {
                "type": "expense|income|transfer",
                "amount": 1000,
                "category": "еда",
                "description": "описание",
                "wallet": "основной"
            },
            "response": "ответ пользователю"
        }
        """
        
        user_prompt = f"""
        Сообщение пользователя: "{message}"
        
        Данные пользователя:
        - Категории: {user_data.get('categories', [])}
        - Кошельки: {user_data.get('wallets', [])}
        - Валюта: {user_data.get('currency', 'KZT')}
        """
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.1,
                max_tokens=500
            )
            
            result = response.choices[0].message.content
            return json.loads(result)
            
        except Exception as e:
            return {
                "type": "error",
                "response": f"Ошибка обработки: {str(e)}"
            }
    
    def analyze_expenses(self, transactions: list, period: str = "month") -> str:
        """
        Анализирует расходы и дает рекомендации
        """
        system_prompt = """
        Ты финансовый аналитик. Проанализируй расходы пользователя и дай полезные рекомендации.
        Будь конкретным и давай практические советы.
        """
        
        user_prompt = f"""
        Расходы за {period}:
        {json.dumps(transactions, ensure_ascii=False, indent=2)}
        
        Проанализируй и дай рекомендации по экономии.
        """
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.3,
                max_tokens=800
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            return f"Ошибка анализа: {str(e)}"

ai_service = AIService() 