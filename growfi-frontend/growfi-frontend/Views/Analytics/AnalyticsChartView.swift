import SwiftUI
import Charts

struct AnalyticsChartView: View {
    let data: [(date: Date, income: Double, expense: Double)]

    var body: some View {
        Chart {
            ForEach(data, id: \.date) { point in
                LineMark(
                    x: .value("Дата", point.date),
                    y: .value("Доходы", point.income)
                )
                .foregroundStyle(Color.green)
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Дата", point.date),
                    y: .value("Расходы", point.expense)
                )
                .foregroundStyle(Color.red)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            let lang = AppLanguageManager.shared.currentLanguage.rawValue
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated).locale(Locale(identifier: lang)))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct AnalyticsChartView_Previews: PreviewProvider {
    static var previews: some View {
        let now = Date()
        let sample = (0..<10).map { i in
            (
                date: Calendar.current.date(byAdding: .day, value: i, to: now)!,
                income: Double.random(in: 0...40000),
                expense: Double.random(in: 0...20000)
            )
        }

        return AnalyticsChartView(data: sample)
            .frame(height: 220)
            .padding()
    }
}
