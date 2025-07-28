import Foundation

struct TransactionDay: Identifiable {
    let id: Int
    let date: Date
    let transactions: [Transaction]
    var total: Double {
        transactions.reduce(0) { sum, transaction in
            switch transaction.type {
            case .income:
                return sum + transaction.amount
            case .expense, .goal_transfer:
                return sum - abs(transaction.amount)
            case .wallet_transfer, .goal:
                // Переводы между кошельками и цели не влияют на общий баланс
                return sum
            }
        }
    }
} 