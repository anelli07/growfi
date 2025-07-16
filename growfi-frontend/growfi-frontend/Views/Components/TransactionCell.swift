import SwiftUI

struct TransactionCell: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.color))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.headline)
                Text(transaction.wallet_name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.amount, specifier: "%.0f") ₸")
                    .font(.headline)
                    .foregroundColor(transaction.type == .income ? .green : ((transaction.type == .expense || transaction.type == .goal_transfer) ? .red : .primary))
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct TransactionCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            TransactionCell(transaction: Transaction(
                id: 1,
                date: Date(),
                type: .expense,
                amount: -2000,
                note: "Магазин",
                title: "Продукты",
                icon: "cart.fill",
                color: "#FF0000",
                wallet_name: "Карта",
                wallet_icon: "creditcard",
                wallet_color: "#4F8A8B"
            ))
            TransactionCell(transaction: Transaction(
                id: 2,
                date: Date(),
                type: .income,
                amount: 40000,
                note: nil,
                title: "Зарплата",
                icon: "dollarsign.circle.fill",
                color: "#00FF00",
                wallet_name: "Карта",
                wallet_icon: "creditcard",
                wallet_color: "#4F8A8B"
            ))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// Для поддержки hex-цвета
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
