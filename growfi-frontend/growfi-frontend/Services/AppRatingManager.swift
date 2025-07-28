import Foundation
import StoreKit
import SwiftUI

class AppRatingManager: ObservableObject {
    static let shared = AppRatingManager()
    
    @Published var showRatingView = false
    
    private let appOpenCountKey = "app_open_count"
    private let lastRatingRequestKey = "last_rating_request_date"
    private let hasRatedKey = "has_rated_app"
    
    private init() {}
    
    // Увеличиваем счетчик открытий приложения
    func incrementAppOpenCount() {
        let currentCount = UserDefaults.standard.integer(forKey: appOpenCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: appOpenCountKey)
    }
    
    // Проверяем, нужно ли показать запрос на оценку
    func shouldShowRatingRequest() -> Bool {
        // Если уже оценили - не показываем
        if UserDefaults.standard.bool(forKey: hasRatedKey) {
            return false
        }
        
        let appOpenCount = UserDefaults.standard.integer(forKey: appOpenCountKey)
        let lastRequestDate = UserDefaults.standard.object(forKey: lastRatingRequestKey) as? Date
        
        // Показываем на втором открытии (appOpenCount == 2)
        // Или если прошло больше 30 дней с последнего запроса
        if appOpenCount == 2 {
            return true
        }
        
        if let lastRequest = lastRequestDate {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day ?? 0
            return daysSinceLastRequest >= 30
        }
        
        return false
    }
    
    // Показываем запрос на оценку
    func requestAppRating() {
        // Записываем дату запроса
        UserDefaults.standard.set(Date(), forKey: lastRatingRequestKey)
        
        // Показываем кастомное окно оценки
        DispatchQueue.main.async {
            self.showRatingView = true
        }
    }
    
    // Открываем приложение в App Store для оценки
    func openAppStoreForRating() {
        // App Store ID для GrowFi: Finance Manager
        let appStoreId = "6748830339"
        if let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    // Отмечаем, что пользователь оценил приложение
    func markAsRated() {
        UserDefaults.standard.set(true, forKey: hasRatedKey)
    }
    
    // Сбрасываем для тестирования
    func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: appOpenCountKey)
        UserDefaults.standard.removeObject(forKey: lastRatingRequestKey)
        UserDefaults.standard.removeObject(forKey: hasRatedKey)
    }
    
    // Получаем текущий счетчик открытий
    func getAppOpenCount() -> Int {
        return UserDefaults.standard.integer(forKey: appOpenCountKey)
    }
} 