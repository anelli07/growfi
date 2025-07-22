import Foundation

enum PlanPeriod: String, Codable, CaseIterable, Identifiable {
    case week
    case month
    var id: String { rawValue }
    var title: String {
        switch self {
        case .week: return "недель"
        case .month: return "месяцев"
        }
    }
} 