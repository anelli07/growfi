import Foundation

struct Goal: Identifiable, Codable {
    let id: Int
    var name: String
    var target_amount: Double
    var current_amount: Double
    let user_id: Int
    var icon: String
    var color: String
    let currency: String
    // --- Для персональных уведомлений и планирования ---
    var planPeriod: PlanPeriod? // .week/.month/или nil
    var planAmount: Double? // сумма взноса
    var createdAt: Date? // дата создания (может отсутствовать в ответе сервера)
    // --- Для настройки уведомлений ---
    var reminderPeriod: String?
    var selectedWeekday: Int?
    var selectedMonthDay: Int?
    var selectedTime: String?
    // ---
    var growthStage: Int {
        guard target_amount > 0 else { return 0 }
        let progress = min(max(current_amount / target_amount, 0), 1)
        return Int(progress * 9)
    }
    enum CodingKeys: String, CodingKey {
        case id, name, target_amount, current_amount, user_id, icon, color, currency
        case planPeriod, planAmount, createdAt
        case reminderPeriod = "reminder_period"
        case selectedWeekday = "selected_weekday"
        case selectedMonthDay = "selected_month_day"
        case selectedTime = "selected_time"
    }
} 
