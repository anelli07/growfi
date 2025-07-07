import SwiftUI

enum CategoryType: String, CaseIterable, Identifiable {
    case продукты = "Продукты"
    case еда = "Еда"
    case развлечения = "Развлечения"
    case транспорт = "Транспорт"
    case зарплата = "Зарплата"
    case кофе = "Кофе"
    case подарок = "Подарок"
    case карманные = "Карманные"
    case здоровье = "Здоровье"
    case другое = "Другое"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .продукты: return .blue
        case .еда: return .green
        case .развлечения: return .pink
        case .транспорт: return .yellow
        case .зарплата: return .green
        case .кофе: return .brown
        case .подарок: return .pink.opacity(0.7)
        case .карманные: return .mint
        case .здоровье: return .red
        case .другое: return .gray
        }
    }

    var icon: String {
        switch self {
        case .продукты: return "cart.fill"
        case .еда: return "fork.knife"
        case .развлечения: return "gamecontroller.fill"
        case .транспорт: return "car.fill"
        case .зарплата: return "dollarsign.circle.fill"
        case .кофе: return "cup.and.saucer.fill"
        case .подарок: return "gift.fill"
        case .карманные: return "creditcard.fill"
        case .здоровье: return "cross.case.fill"
        case .другое: return "questionmark.circle"
        }
    }

    static func from(name: String) -> CategoryType {
        CategoryType.allCases.first(where: { $0.rawValue == name }) ?? .другое
    }
} 