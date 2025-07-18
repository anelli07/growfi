import SwiftUI

import SwiftUI

struct BalanceCard: View {
    let balance: Double
    let income: Double
    let expense: Double
    let currency: String

    var body: some View {
        VStack(spacing: 16) {
            // Сальдо заголовок
            Text("Balance".localized)
                .font(.subheadline)
                .foregroundColor(.gray)

            // Сумма
            Text("\(Int(balance)) \(currency)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.black)

            // Поступления и Списания
            HStack(spacing: 12) {
                StatTile(
                    title: "Income".localized,
                    value: income,
                    color: .green,
                    currency: currency,
                )
                StatTile(
                    title: "Expense".localized,
                    value: expense,
                    color: .red,
                    currency: currency,
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private func StatTile(title: String, value: Double, color: Color, currency: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text("\(Int(value)) \(currency)")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct BalanceCard_Previews: PreviewProvider {
    static var previews: some View {
        BalanceCard(
            balance: 36950,
            income: 40000,
            expense: 3050,
            currency: "₸"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
