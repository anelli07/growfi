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
            Transaction(
                id: Int(Date().timeIntervalSince1970 * 1000),
                date: today,
                type: .expense,
                amount: -2000,
                note: "Магазин",
                title: "Продукты",
                icon: "cart.fill",
                color: "#FF0000",
                wallet_name: "Карта",
                wallet_icon: "creditcard",
                wallet_color: "#4F8A8B"
            ),
            Transaction(
                id: Int(Date().timeIntervalSince1970 * 1001),
                date: today,
                type: .income,
                amount: 40000,
                note: nil,
                title: "Зарплата",
                icon: "dollarsign.circle.fill",
                color: "#00FF00",
                wallet_name: "Карта",
                wallet_icon: "creditcard",
                wallet_color: "#4F8A8B"
            ),
            Transaction(
                id: Int(Date().timeIntervalSince1970 * 1002),
                date: today,
                type: .expense,
                amount: -800,
                note: "",
                title: "Кофе",
                icon: "cup.and.saucer.fill",
                color: "#A0522D",
                wallet_name: "Карта",
                wallet_icon: "creditcard",
                wallet_color: "#4F8A8B"
            ),
            Transaction(
                id: Int(Date().timeIntervalSince1970 * 1003),
                date: yesterday,
                type: .expense,
                amount: -500,
                note: "Метро",
                title: "Транспорт",
                icon: "tram.fill",
                color: "#007AFF",
                wallet_name: "Карта",
                wallet_icon: "creditcard",
                wallet_color: "#4F8A8B"
            ),
            Transaction(
                id: Int(Date().timeIntervalSince1970 * 1004),
                date: yesterday,
                type: .expense,
                amount: -1000,
                note: "Друзья",
                title: "Подарок",
                icon: "gift.fill",
                color: "#FF69B4",
                wallet_name: "Наличные",
                wallet_icon: "banknote",
                wallet_color: "#FFD700"
            ),
            Transaction(
                id: Int(Date().timeIntervalSince1970 * 1005),
                date: twoDaysAgo,
                type: .expense,
                amount: -1200,
                note: nil,
                title: "Еда",
                icon: "fork.knife",
                color: "#FFA500",
                wallet_name: "Карта",
                wallet_icon: "creditcard",
                wallet_color: "#4F8A8B"
            )
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
        let groupedCat = Dictionary(grouping: filtered) { $0.title }
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
            let txs = transactions.filter { $0.title == cat.category }
            return selectedType == .income ? txs.contains(where: { $0.type == .income }) : txs.contains(where: { $0.type == .expense })
        }
    }
} 
 
