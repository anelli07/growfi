import Foundation

enum PeriodType: String, CaseIterable, Identifiable {
    case week = "Неделя"
    case month = "Месяц"
    case quarter = "Квартал"
    case halfYear = "Полгода"
    case year = "Год"
    case all = "Весь период"
    case custom = "Произвольный"
    
    var id: String { self.rawValue }
} 