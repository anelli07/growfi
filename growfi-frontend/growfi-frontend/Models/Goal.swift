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
        case planPeriod = "plan_period"
        case planAmount = "plan_amount"
        case createdAt = "created_at"
        case reminderPeriod = "reminder_period"
        case selectedWeekday = "selected_weekday"
        case selectedMonthDay = "selected_month_day"
        case selectedTime = "selected_time"
    }
    
    // Обычный инициализатор для создания объектов Goal
    init(id: Int, name: String, target_amount: Double, current_amount: Double, user_id: Int, icon: String, color: String, currency: String, planPeriod: PlanPeriod? = nil, planAmount: Double? = nil, createdAt: Date? = nil, reminderPeriod: String? = nil, selectedWeekday: Int? = nil, selectedMonthDay: Int? = nil, selectedTime: String? = nil) {
        self.id = id
        self.name = name
        self.target_amount = target_amount
        self.current_amount = current_amount
        self.user_id = user_id
        self.icon = icon
        self.color = color
        self.currency = currency
        self.planPeriod = planPeriod
        self.planAmount = planAmount
        self.createdAt = createdAt
        self.reminderPeriod = reminderPeriod
        self.selectedWeekday = selectedWeekday
        self.selectedMonthDay = selectedMonthDay
        self.selectedTime = selectedTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        target_amount = try container.decode(Double.self, forKey: .target_amount)
        current_amount = try container.decode(Double.self, forKey: .current_amount)
        user_id = try container.decode(Int.self, forKey: .user_id)
        icon = try container.decode(String.self, forKey: .icon)
        color = try container.decode(String.self, forKey: .color)
        currency = try container.decode(String.self, forKey: .currency)
        
        // Декодируем plan_period как строку и конвертируем в enum
        if let planPeriodString = try container.decodeIfPresent(String.self, forKey: .planPeriod) {
            planPeriod = PlanPeriod(rawValue: planPeriodString)
        } else {
            planPeriod = nil
        }
        
        planAmount = try container.decodeIfPresent(Double.self, forKey: .planAmount)
        
        // Декодируем created_at как строку и конвертируем в Date
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            print("DEBUG: createdAtString = \(createdAtString)")
            
            // Пробуем парсить дату вручную
            let components = createdAtString.components(separatedBy: ["T", ".", ":"])
            print("DEBUG: Components: \(components)")
            
            if components.count >= 4 {
                // Разбираем дату отдельно
                let datePart = components[0]
                let dateParts = datePart.components(separatedBy: "-")
                print("DEBUG: Date components: \(dateParts)")
                
                let year = Int(dateParts[0]) ?? 0
                let month = Int(dateParts[1]) ?? 0
                let day = Int(dateParts[2]) ?? 0
                let hour = Int(components[1]) ?? 0
                let minute = Int(components[2]) ?? 0
                let second = Int(components[3]) ?? 0
                
                print("DEBUG: Parsed components - year: \(year), month: \(month), day: \(day), hour: \(hour), minute: \(minute), second: \(second)")
                
                var dateComponents = DateComponents()
                dateComponents.year = year
                dateComponents.month = month
                dateComponents.day = day
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.second = second
                dateComponents.timeZone = TimeZone(abbreviation: "UTC")
                
                var calendar = Calendar.current
                calendar.timeZone = TimeZone(abbreviation: "UTC")!
                createdAt = calendar.date(from: dateComponents)
                print("DEBUG: Manual parsing result: \(createdAt?.description ?? "nil")")
            }
            
            if createdAt == nil {
                // Если ручной парсинг не сработал, пробуем обрезать микросекунды
                var adjustedString = createdAtString
                if let dotIndex = createdAtString.firstIndex(of: ".") {
                    let endIndex = createdAtString.index(dotIndex, offsetBy: 4) // ".SSS"
                    adjustedString = String(createdAtString[..<endIndex])
                    print("DEBUG: Adjusted string: \(adjustedString)")
                }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                createdAt = formatter.date(from: adjustedString)
                print("DEBUG: Formatter attempt: \(createdAt?.description ?? "nil")")
            }
            
            print("DEBUG: Final result = \(createdAt?.description ?? "nil")")
        } else {
            print("DEBUG: createdAtString is nil")
            createdAt = nil
        }
        
        reminderPeriod = try container.decodeIfPresent(String.self, forKey: .reminderPeriod)
        selectedWeekday = try container.decodeIfPresent(Int.self, forKey: .selectedWeekday)
        selectedMonthDay = try container.decodeIfPresent(Int.self, forKey: .selectedMonthDay)
        selectedTime = try container.decodeIfPresent(String.self, forKey: .selectedTime)
    }
} 
