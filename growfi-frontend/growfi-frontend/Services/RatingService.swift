import Foundation

class RatingService {
    static let shared = RatingService()
    
    private init() {}
    
    // Отправляем оценку на сервер
    func submitRating(rating: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            completion(.failure(NSError(domain: "No token", code: 401)))
            return
        }
        
        // Здесь можно добавить реальный API запрос
        // Пока что просто имитируем успешную отправку
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(()))
        }
    }
    
    // Сохраняем оценку локально
    func saveRatingLocally(rating: Int) {
        UserDefaults.standard.set(rating, forKey: "user_app_rating")
        UserDefaults.standard.set(Date(), forKey: "rating_date")
    }
    
    // Получаем сохраненную оценку
    func getSavedRating() -> Int? {
        return UserDefaults.standard.object(forKey: "user_app_rating") as? Int
    }
    
    // Получаем дату оценки
    func getRatingDate() -> Date? {
        return UserDefaults.standard.object(forKey: "rating_date") as? Date
    }
} 