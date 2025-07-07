import SwiftUI
import Foundation

enum TransactionType: String, Codable {
    case income, expense
}

struct Transaction: Identifiable, Codable {
    let id: UUID
    let date: Date
    var category: String
    var amount: Double
    let type: TransactionType
    let note: String?
    let wallet: String
} 
