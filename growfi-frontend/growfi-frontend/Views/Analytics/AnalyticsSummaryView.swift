import SwiftUI

struct AnalyticsSummaryView: View {
    let income: Double
    let expense: Double
    let balance: Double
    var currency: String = "₸"

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Доходы")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int(income)) \(currency)")
                    .font(.title3).bold()
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                Text("Расходы")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int(expense)) \(currency)")
                    .font(.title3).bold()
                    .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                Text("Итого")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int(balance)) \(currency)")
                    .font(.title3).bold()
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

struct AnalyticsSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsSummaryView(income: 40000, expense: 13050, balance: 26950)
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 
