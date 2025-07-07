import SwiftUI

struct TransactionCell: View {
    let transaction: Transaction

    var body: some View {
        let type = CategoryType.from(name: transaction.category)
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .font(.system(size: 18, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category)
                    .font(.subheadline)
                Text(transaction.wallet)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("\(transaction.type == .income ? "+" : "-")\(Int(abs(transaction.amount)))")
                .foregroundColor(transaction.type == .income ? .green : .red)
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
                id: UUID(),
                date: Date(),
                category: "Продукты",
                amount: -2000,
                type: .expense,
                note: "Магазин",
                wallet: "Карта"
            ))
            TransactionCell(transaction: Transaction(
                id: UUID(),
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
