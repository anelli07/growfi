import SwiftUI
import Foundation

enum TransactionType: String, Codable {
    case income, expense, goal, wallet_transfer, goal_transfer
}

struct Transaction: Identifiable, Codable {
    let id: Int
    let date: Date
    let type: TransactionType
    var amount: Double
    let note: String?
    // Новые поля для истории
    var title: String
    let icon: String
    let color: String
    let wallet_name: String
    let wallet_icon: String?
    let wallet_color: String?
} 
