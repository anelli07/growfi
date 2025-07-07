import SwiftUI

struct AnalyticsCategoryScrollView: View {
    let categories: [CategoryStat]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories) { cat in
                    let type = CategoryType.from(name: cat.category)
                    VStack(spacing: 6) {
                        Circle()
                            .fill(type.color.opacity(0.18))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                    .font(.system(size: 20, weight: .medium))
                            )
                        Text(cat.category)
                            .font(.caption)
                            .lineLimit(1)
                            .frame(width: 60)
                        Text("\(Int(cat.total))")
                            .font(.subheadline).bold()
                            .foregroundColor(.primary)
                    }
                    .frame(width: 68)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 90)
    }
}

struct AnalyticsCategoryScrollView_Previews: PreviewProvider {
    static var previews: some View {
        let cats = [
            CategoryStat(category: "Продукты", total: 5000, color: .blue),
            CategoryStat(category: "Еда", total: 3000, color: .green),
            CategoryStat(category: "Развлечения", total: 2000, color: .pink)
        ]
        AnalyticsCategoryScrollView(categories: cats)
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 