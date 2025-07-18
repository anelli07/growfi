import Foundation

enum PeriodType: CaseIterable, Identifiable {
    case week, month, quarter, halfYear, year, all, custom
    var id: String { String(describing: self) }
    var localized: String {
        switch self {
        case .week: return "period_week".localized
        case .month: return "period_month".localized
        case .quarter: return "period_quarter".localized
        case .halfYear: return "period_halfyear".localized
        case .year: return "period_year".localized
        case .all: return "period_all".localized
        case .custom: return "period_custom".localized
        }
    }
}

// --- Расширение для вычисления диапазона дат и форматирования ---
extension PeriodType {
    func dateRange(containing date: Date = Date(), customRange: (Date, Date)? = nil) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        switch self {
        case .week:
            let weekday = calendar.component(.weekday, from: date)
            // Неделя: с понедельника по воскресенье
            let daysFromMonday = (weekday + 5) % 7
            let start = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: date))!
            let end = calendar.date(byAdding: .day, value: 6, to: start)!.endOfDay
            return (start, end)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: date)
            let start = calendar.date(from: comps)!
            let range = calendar.range(of: .day, in: .month, for: start)!
            let end = calendar.date(byAdding: .day, value: range.count - 1, to: start)!.endOfDay
            return (start, end)
        case .quarter:
            let comps = calendar.dateComponents([.year, .month], from: date)
            let month = ((comps.month! - 1) / 3) * 3 + 1
            let start = calendar.date(from: DateComponents(year: comps.year, month: month, day: 1))!
            let endMonth = month + 2
            let endDate = calendar.date(from: DateComponents(year: comps.year, month: endMonth, day: 1))!
            let range = calendar.range(of: .day, in: .month, for: endDate)!
            let end = calendar.date(byAdding: .day, value: range.count - 1, to: endDate)!.endOfDay
            return (start, end)
        case .halfYear:
            let comps = calendar.dateComponents([.year, .month], from: date)
            let month = comps.month!
            let startMonth = month <= 6 ? 1 : 7
            let start = calendar.date(from: DateComponents(year: comps.year, month: startMonth, day: 1))!
            let endMonth = startMonth + 5
            let endDate = calendar.date(from: DateComponents(year: comps.year, month: endMonth, day: 1))!
            let range = calendar.range(of: .day, in: .month, for: endDate)!
            let end = calendar.date(byAdding: .day, value: range.count - 1, to: endDate)!.endOfDay
            return (start, end)
        case .year:
            let comps = calendar.dateComponents([.year], from: date)
            let start = calendar.date(from: comps)!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!.addingTimeInterval(-1).endOfDay
            return (start, end)
        case .all:
            return (Date.distantPast, Date.distantFuture)
        case .custom:
            if let custom = customRange { return custom }
            return (date, date)
        }
    }

    func formattedRange(containing date: Date = Date(), customRange: (Date, Date)? = nil) -> String {
        let (start, end) = dateRange(containing: date, customRange: customRange)
        let lang = AppLanguageManager.shared.currentLanguage.rawValue
        let df = DateFormatter()
        df.locale = Locale(identifier: lang)
        switch self {
        case .week:
            df.dateFormat = "dd MMMM"
            let startStr = df.string(from: start)
            let endStr = df.string(from: end)
            let year = Calendar.current.component(.year, from: end)
            return "\(startStr) – \(endStr), \(year)"
        case .month:
            df.dateFormat = "LLLL yyyy"
            return df.string(from: start).capitalized
        case .quarter:
            let quarter = (Calendar.current.component(.month, from: start) - 1) / 3 + 1
            let year = Calendar.current.component(.year, from: start)
            return String(format: "%@ %d", "quarter".localized, quarter) + " " + String(year)
        case .halfYear:
            let month = Calendar.current.component(.month, from: start)
            let year = Calendar.current.component(.year, from: start)
            return month == 1 ? String(format: "%@ %d", "first_half".localized, year) : String(format: "%@ %d", "second_half".localized, year)
        case .year:
            let year = Calendar.current.component(.year, from: start)
            return String(format: "%d %@", year, "year".localized)
        case .all:
            return "Весь период".localized
        case .custom:
            df.dateFormat = "dd MMMM yyyy"
            let startStr = df.string(from: start)
            let endStr = df.string(from: end)
            return "\(startStr) – \(endStr)"
        }
    }
}

extension Date {
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
} 