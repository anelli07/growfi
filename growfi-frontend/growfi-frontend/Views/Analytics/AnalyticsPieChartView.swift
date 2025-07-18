import SwiftUI
import Charts

struct PieLabelInfo {
    let percent: Double
    let percentX: CGFloat
    let percentY: CGFloat
    let lineStart: CGPoint
    let lineEnd: CGPoint
    let labelX: CGFloat
    let labelY: CGFloat
    let category: String
    let color: Color
}

struct AnalyticsPieChartView: View {
    let data: [CategoryStat]
    
    var total: Double {
        data.map { $0.total }.reduce(0, +)
    }
    
    var angles: [Double] {
        var result: [Double] = []
        var current: Double = 0
        for stat in data {
            let angle = stat.total / max(total, 0.0001) * 360.0
            result.append(current)
            current += angle
        }
        return result
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Chart(data) { stat in
                    SectorMark(
                        angle: .value("Сумма", stat.total),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(stat.color)
                }
                .chartLegend(.hidden)
                PieChartLabelsOverlay(
                    labels: makeLabels(
                        data: data,
                        angles: angles,
                        geometry: geometry,
                        total: total
                    )
                )
            }
        }
    }
    
    func makeLabels(data: [CategoryStat], angles: [Double], geometry: GeometryProxy, total: Double) -> [PieLabelInfo] {
        let startOffset = -90.0
        let topLimit = geometry.size.height * 0.08
        let bottomLimit = geometry.size.height * 0.92
        let sideOffset: CGFloat = 40
        let radius = min(geometry.size.width, geometry.size.height) / 2
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        var result: [PieLabelInfo] = []
        for (index, item) in data.enumerated() {
            let percent = total > 0 ? item.total / total * 100 : 0
            if percent < 10 { continue }
            let startAngle = angles[index]
            let endAngle = index + 1 < angles.count ? angles[index + 1] : 360.0
            let midAngle = (startAngle + endAngle) / 2.0 + startOffset
            let rad = Angle(degrees: midAngle).radians
            let percentRadius = radius * 0.75
            let percentX = center.x + CGFloat(cos(rad)) * percentRadius
            let percentY = center.y + CGFloat(sin(rad)) * percentRadius
            let lineStart = CGPoint(
                x: center.x + CGFloat(cos(rad)) * radius * 0.95,
                y: center.y + CGFloat(sin(rad)) * radius * 0.95
            )
            let labelRadius = radius * 1.18
            var labelX = center.x + CGFloat(cos(rad)) * labelRadius
            var labelY = center.y + CGFloat(sin(rad)) * labelRadius
            let alignRight = cos(rad) >= 0
            if labelY < topLimit {
                labelY = topLimit
                labelX = alignRight ? center.x + radius + sideOffset : center.x - radius - sideOffset
            }
            if labelY > bottomLimit {
                labelY = bottomLimit
                labelX = alignRight ? center.x + radius + sideOffset : center.x - radius - sideOffset
            }
            // Линия теперь до ближайшей точки к подписи (на 16pt ближе к кругу)
            let isSide = (labelY == topLimit) || (labelY == bottomLimit)
            let textWidth = CGFloat(item.category.count) * 8.0
            let lineEnd: CGPoint
            if isSide {
                if alignRight {
                    lineEnd = CGPoint(x: labelX - textWidth/2 - 4, y: labelY)
                } else {
                    lineEnd = CGPoint(x: labelX + textWidth/2 + 4, y: labelY)
                }
            } else {
                let labelRadiusForLine = labelRadius - 10
                lineEnd = CGPoint(
                    x: center.x + CGFloat(cos(rad)) * labelRadiusForLine,
                    y: center.y + CGFloat(sin(rad)) * labelRadiusForLine
                )
            }
            result.append(PieLabelInfo(
                percent: percent,
                percentX: percentX,
                percentY: percentY,
                lineStart: lineStart,
                lineEnd: lineEnd,
                labelX: labelX,
                labelY: labelY,
                category: item.category,
                color: item.color
            ))
        }
        return result
    }
}

struct PieChartLabelsOverlay: View {
    let labels: [PieLabelInfo]
    var body: some View {
        ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
            Group {
                Text("\(label.percent, specifier: "%.1f")%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .position(x: label.percentX, y: label.percentY)
                Path { path in
                    path.move(to: label.lineStart)
                    path.addLine(to: label.lineEnd)
                }
                .stroke(.gray, lineWidth: 1.2)
                Text(label.category)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                    .position(x: label.labelX, y: label.labelY)
            }
        }
    }
}

struct AnalyticsPieChartView_Previews: PreviewProvider {
    static var previews: some View {
        let data = [
            CategoryStat(category: "Продукты", total: 5000, color: .blue, categoryIcon: "cart.fill"),
            CategoryStat(category: "Еда", total: 3000, color: .green, categoryIcon: "fork.knife"),
            CategoryStat(category: "Развлечения", total: 2000, color: .pink, categoryIcon: "gamecontroller.fill")
        ]
        AnalyticsPieChartView(data: data)
            .frame(height: 260)
            .padding()
    }
} 
