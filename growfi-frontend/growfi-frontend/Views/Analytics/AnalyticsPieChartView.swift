import SwiftUI
import Charts

struct AnalyticsPieChartView: View {
    let data: [CategoryStat]
    var body: some View {
        Chart(data) { stat in
            SectorMark(
                angle: .value("Сумма", stat.total),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(stat.color)
        }
        .chartLegend(.hidden)
    }
}

struct AnalyticsPieChartView_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            CategoryStat(category: "Продукты", total: 5000, color: .blue),
            CategoryStat(category: "Еда", total: 3000, color: .green),
            CategoryStat(category: "Развлечения", total: 2000, color: .pink)
        ]
        AnalyticsPieChartView(data: data)
            .frame(height: 260)
            .padding()
    }
} 