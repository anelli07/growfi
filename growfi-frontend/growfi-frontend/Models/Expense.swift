import Foundation

struct Expense: Identifiable, Codable {
    let id: Int
    var name: String
    var icon: String
    var color: String
    let user_id: Int
    var description: String?
    let category_id: Int?
    let wallet_id: Int?
    var amount: Double = 0
} 
