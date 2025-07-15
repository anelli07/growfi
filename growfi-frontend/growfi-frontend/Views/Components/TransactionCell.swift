import SwiftUI

struct TransactionCell: View {
    let transaction: Transaction

    var body: some View {
        let type = transaction.type
        let catType = CategoryType.from(name: transaction.category ?? "")
        let icon: String = {
            switch type {
            case .income, .expense:
                return catType.icon
            case .goal:
                return "leaf.circle.fill"
            case .wallet_transfer:
                return "arrow.left.arrow.right.circle.fill"
            case .goal_transfer:
                return "target"
            }
        }()
        let color: Color = {
            switch type {
            case .income:
                return .green
            case .expense:
                return .red
            case .goal:
                return .green
            case .wallet_transfer:
                return .blue
            case .goal_transfer:
                return .purple
            }
        }()
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .medium))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category ?? (type == .goal ? "Цель" : ""))
                    .font(.subheadline)
                Text(transaction.wallet ?? "")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(type == .income ? "+" : type == .goal ? "→" : "-")\(Int(abs(transaction.amount)))")
                .foregroundColor(type == .income ? .green : type == .goal ? .green : .red)
                .font(.headline)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

struct TransactionCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            TransactionCell(transaction: Transaction(
                id: 1,
                date: Date(),
                category: "Продукты",
                amount: -2000,
                type: .expense,
                note: "Магазин",
                wallet: "Карта"
            ))
            TransactionCell(transaction: Transaction(
                id: 2,
                date: Date(),
                category: "Зарплата",
                amount: 40000,
                type: .income,
                note: nil,
                wallet: "Карта"
            ))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
