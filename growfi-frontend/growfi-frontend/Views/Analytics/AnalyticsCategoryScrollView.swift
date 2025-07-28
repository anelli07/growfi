import SwiftUI

struct AnalyticsCategoryScrollView: View {
    let categories: [CategoryStat]
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        if categories.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.5))
                Text("no_categories_available".localized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(categories) { cat in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(cat.color.opacity(0.18))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: cat.categoryIcon)
                                    .foregroundColor(cat.color)
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
    }
}

struct AnalyticsCategoryScrollView_Previews: PreviewProvider {
    static var previews: some View {
        let cats = [
            CategoryStat(category: "Продукты", total: 5000, color: .blue, categoryIcon: "cart.fill"),
            CategoryStat(category: "Еда", total: 3000, color: .green, categoryIcon: "fork.knife"),
            CategoryStat(category: "Развлечения", total: 2000, color: .pink, categoryIcon: "gamecontroller.fill")
        ]
        AnalyticsCategoryScrollView(categories: cats)
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 
