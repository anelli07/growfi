import Foundation

extension String {
    private static var localizationCache: [String: String] = [:]
    private static var currentLanguage: String = AppLanguageManager.shared.currentLanguage.rawValue
    
    static func clearLocalizationCache() {
        localizationCache.removeAll()
    }
    
    var localized: String {
        let lang = AppLanguageManager.shared.currentLanguage.rawValue
        
        // Если язык изменился, очищаем кэш
        if String.currentLanguage != lang {
            String.currentLanguage = lang
            String.clearLocalizationCache()
        }
        
        // Проверяем кэш
        let cacheKey = "\(self)_\(lang)"
        if let cached = String.localizationCache[cacheKey] {
            return cached
        }
        
        // Загружаем перевод
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            let result = NSLocalizedString(self, comment: "")
            String.localizationCache[cacheKey] = result
            return result
        }
        
        let result = NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
        String.localizationCache[cacheKey] = result
        return result
    }
    
    var localizedIfDefault: String {
        let defaultKeys = [
            // Wallets
            "Wallet", "Кошелек", "Карта", "Card", "Cash", "Наличные",
            // Incomes
            "Income", "Доход", "Salary", "Зарплата",
            // Goals
            "Goal", "Цель", "Give", "Пожертвование",
            // Expenses
            "Expense", "Расход",
            // Categories (en/ru)
            "Food", "Еда", "Groceries", "Продукты", "Transport", "Транспорт",
            "Entertainment", "Развлечения", "Health", "Здоровье", "Communication", "Связь",
            "Travel", "Путешествия", "Clothes", "Одежда", "Beauty", "Красота",
            "Gift", "Подарок", "Coffee", "Кофе", "Pocket Money", "Карманные",
            "Other", "Другое"
        ]
        return defaultKeys.contains(self) ? self.localized : self
    }
} 