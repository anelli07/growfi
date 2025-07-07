import SwiftUI

struct TransactionDaySection: View {
    let day: TransactionDay
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(day.date, formatter: dateFormatter)
                    .font(.subheadline).bold()
                Spacer()
                Text("\(day.total >= 0 ? "+" : "-")\(Int(abs(day.total)))")
                    .font(.subheadline)
                    .foregroundColor(day.total >= 0 ? .green : .red)
            }
            .padding(.bottom, 2)
            ForEach(day.transactions) { tx in
                TransactionCell(transaction: tx)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
    }
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.locale = Locale(identifier: "ru_RU")
    df.setLocalizedDateFormatFromTemplate("d MMMM yyyy, EEEE")
    return df
}()

struct TransactionDaySection_Previews: PreviewProvider {
    static var previews: some View {
        let date = Date()
        let txs = [
            Transaction(id: UUID(), date: date, category: "Продукты", amount: -2000, type: .expense, note: "Магазин", wallet: "Карта"),
            Transaction(id: UUID(), date: date, category: "Зарплата", amount: 40000, type: .income, note: nil, wallet: "Карта")
        ]
        let day = TransactionDay(date: date, transactions: txs)
        return TransactionDaySection(day: day)
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 
