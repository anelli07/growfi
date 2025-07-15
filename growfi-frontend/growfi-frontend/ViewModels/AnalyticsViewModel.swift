import Foundation
import SwiftUI

struct CategoryStat: Identifiable {
    let id = UUID()
    let category: String
    let total: Double
    let color: Color
}

class AnalyticsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var selectedPeriod: PeriodType = .month
    @Published var chartType: ChartType = .line
    @Published var groupedByDay: [(date: Date, income: Double, expense: Double)] = []
    @Published var groupedByCategory: [CategoryStat] = []
    @Published var incomeTotal: Double = 0
    @Published var expenseTotal: Double = 0
    @Published var balance: Double = 0
    @Published var selectedType: TransactionType = .expense

    enum ChartType { case line, pie }

    private var allTransactions: [Transaction] = []

    init() {
        loadTestData()
        applyFilters()
    }

    func loadTestData() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        allTransactions = [
            Transaction(id: Int(Date().timeIntervalSince1970 * 1000), date: today, category: "Продукты", amount: -2000, type: .expense, note: "Магазин", wallet: "Карта"),
            Transaction(id: Int(Date().timeIntervalSince1970 * 1001), date: today, category: "Зарплата", amount: 40000, type: .income, note: nil, wallet: "Карта"),
            Transaction(id: Int(Date().timeIntervalSince1970 * 1002), date: today, category: "Кофе", amount: -800, type: .expense, note: "", wallet: "Карта"),
            Transaction(id: Int(Date().timeIntervalSince1970 * 1003), date: yesterday, category: "Транспорт", amount: -500, type: .expense, note: "Метро", wallet: "Карта"),
            Transaction(id: Int(Date().timeIntervalSince1970 * 1004), date: yesterday, category: "Подарок", amount: -1000, type: .expense, note: "Друзья", wallet: "Наличные"),
            Transaction(id: Int(Date().timeIntervalSince1970 * 1005), date: twoDaysAgo, category: "Еда", amount: -1200, type: .expense, note: nil, wallet: "Карта")
        ]
    }

    func applyFilters() {
        let calendar = Calendar.current
        let now = Date()
        let filtered = allTransactions.filter { tx in
            switch selectedPeriod {
            case .month:
                return calendar.isDate(tx.date, equalTo: now, toGranularity: .month)
            case .week:
                return calendar.isDate(tx.date, equalTo: now, toGranularity: .weekOfYear)
            case .year:
                return calendar.isDate(tx.date, equalTo: now, toGranularity: .year)
            case .quarter, .halfYear, .all, .custom:
                return true // для MVP
            }
        }
        transactions = filtered
        // Группировка по дням
        let groupedDay = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.date) }
        let sortedDay = groupedDay.map { (date, txs) -> (Date, Double, Double) in
            let income = txs.filter { $0.type == .income }.map { $0.amount }.reduce(0, +)
            let expense = abs(txs.filter { $0.type == .expense }.map { $0.amount }.reduce(0, +))
            return (date, income, expense)
        }.sorted { $0.0 < $1.0 }
        groupedByDay = sortedDay
        // Группировка по категориям
        let groupedCat = Dictionary(grouping: filtered) { $0.category }
        groupedByCategory = groupedCat.map { (cat, txs) in
            let total = txs.map { abs($0.amount) }.reduce(0, +)
            let type = CategoryType.from(name: cat ?? "")
            return CategoryStat(category: cat ?? "", total: total, color: type.color)
        }.sorted { $0.total > $1.total }
        // Итоги
        incomeTotal = filtered.filter { $0.type == .income }.map { $0.amount }.reduce(0, +)
        expenseTotal = abs(filtered.filter { $0.type == .expense }.map { $0.amount }.reduce(0, +))
        balance = incomeTotal - expenseTotal
    }

    func updatePeriod(_ period: PeriodType) {
        selectedPeriod = period
        applyFilters()
    }

    func selectPreviousPeriod() {
        guard let currentIndex = PeriodType.allCases.firstIndex(of: selectedPeriod),
              currentIndex > 0 else { return }
        let newPeriod = PeriodType.allCases[currentIndex - 1]
        updatePeriod(newPeriod)
    }

    func selectNextPeriod() {
        guard let currentIndex = PeriodType.allCases.firstIndex(of: selectedPeriod),
              currentIndex < PeriodType.allCases.count - 1 else { return }
        let newPeriod = PeriodType.allCases[currentIndex + 1]
        updatePeriod(newPeriod)
    }

    func setChartType(_ type: ChartType) {
        chartType = type
    }

    var filteredCategories: [CategoryStat] {
        groupedByCategory.filter { cat in
            let txs = transactions.filter { $0.category == cat.category }
            return selectedType == .income ? txs.contains(where: { $0.type == .income }) : txs.contains(where: { $0.type == .expense })
        }
    }
} 
 
