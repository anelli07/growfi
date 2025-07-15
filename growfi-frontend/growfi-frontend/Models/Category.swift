import Foundation

struct Category: Identifiable, Codable {
    let id: Int
    let name: String
    let type: String // "INCOME" или "EXPENSE"
} 