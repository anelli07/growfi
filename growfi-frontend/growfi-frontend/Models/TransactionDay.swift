import Foundation

struct TransactionDay: Identifiable {
    let id: Int
    let date: Date
    let transactions: [Transaction]
    var total: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }
} 