import SwiftUI

struct TransactionDaySection: View {
    let day: TransactionDay
    var onDeleteTransaction: ((Int) -> Void)? = nil
    @ObservedObject private var langManager = AppLanguageManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formattedDate(day.date))
                    .font(.subheadline).bold()
                Spacer()
                Text("\(day.total >= 0 ? "+" : "-")\(Int(abs(day.total)))")
                    .font(.subheadline)
                    .foregroundColor(day.total >= 0 ? .green : .red)
            }
            .padding(.bottom, 2)
            ForEach(day.transactions) { tx in
                TransactionCell(transaction: tx) {
                    onDeleteTransaction?(tx.id)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
    }
    private func formattedDate(_ date: Date) -> String {
        let lang = langManager.currentLanguage.rawValue
        let locale = Locale(identifier: lang)
        let df = DateFormatter()
        df.locale = locale
        df.setLocalizedDateFormatFromTemplate("d MMMM yyyy, EEEE")
        return df.string(from: date)
    }
}

struct TransactionDaySection_Previews: PreviewProvider {
    static var previews: some View {
        let date = Date()
        let txs = [
            Transaction(
                id: 1,
                date: date,
                type: .expense,
                amount: -2000,
                note: "Магазин",
                title: "Продукты",
                icon: "🛒",
                color: "#FF0000",
                wallet_name: "Карта",
                wallet_icon: "💳",
                wallet_color: "#0000FF",
                goal_id: nil
            ),
            Transaction(
                id: 2,
                date: date,
                type: .income,
                amount: 40000,
                note: nil,
                title: "Зарплата",
                icon: "💸",
                color: "#00FF00",
                wallet_name: "Карта",
                wallet_icon: "💳",
                wallet_color: "#0000FF",
                goal_id: nil
            )
        ]
        let day = TransactionDay(id: 1, date: date, transactions: txs)
        return TransactionDaySection(day: day)
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 
