import Foundation
import SwiftUI

struct CategoryStat: Identifiable {
    let id = UUID()
    let category: String
    let total: Double
    let color: Color
    let categoryIcon: String
}

class PeriodSelectionViewModel: ObservableObject {
    @Published var selectedPeriod: PeriodType = .month
    @Published var customRange: (Date, Date)? = nil
    
    var currentRange: (start: Date, end: Date) {
        selectedPeriod.dateRange(containing: Date(), customRange: customRange)
    }
    
    var formatted: String {
        selectedPeriod.formattedRange(containing: Date(), customRange: customRange)
    }
    
    func select(period: PeriodType) {
        selectedPeriod = period
        if period != .custom { customRange = nil }
    }
    func setCustomRange(_ range: (Date, Date)) {
        selectedPeriod = .custom
        customRange = range
    }
}

class AnalyticsViewModel: ObservableObject {
    @Published var periodVM = PeriodSelectionViewModel()
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
        fetchTransactions()
        applyFilters()
    }

    func fetchTransactions() {
        guard let token = UserDefaults.standard.string(forKey: "access_token"), !token.isEmpty else {
            print("[AnalyticsViewModel] Нет access_token, не делаю fetchTransactions")
            return
        }
        ApiService.shared.fetchTransactions(token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let txs):
                    print("[AnalyticsViewModel] Получено транзакций с бэка:", txs)
                    self?.allTransactions = txs
                    self?.applyFilters()
                case .failure(let err):
                    print("[AnalyticsViewModel] Ошибка декодирования или запроса:", err.localizedDescription)
                }
            }
        }
    }

    func applyFilters() {
        let range = periodVM.currentRange
        let filtered = allTransactions.filter { tx in
            tx.date >= range.start && tx.date <= range.end
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
            return CategoryStat(category: cat ?? "", total: total, color: type.color, categoryIcon: type.icon)
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

    struct CategoryKey: Hashable {
        let icon: String
        let color: String
        let title: String
    }

    var filteredCategories: [CategoryStat] {
        let range = periodVM.currentRange
        let calendar = Calendar.current
        let filtered = transactions.filter { tx in
            let txDay = calendar.startOfDay(for: tx.date)
            let startDay = calendar.startOfDay(for: range.start)
            let endDay = calendar.startOfDay(for: range.end)
            if selectedType == .income {
                return txDay >= startDay && txDay <= endDay && tx.type == .income
            } else if selectedType == .expense {
                return txDay >= startDay && txDay <= endDay && tx.type == .expense
            } else if selectedType == .goal {
                // Включаем все транзакции с type == .goal, .goal_transfer, а также с title содержащим 'цель' (на всякий случай)
                return txDay >= startDay && txDay <= endDay && (tx.type == .goal || tx.type == .goal_transfer || tx.title.lowercased().contains("цель"))
            } else {
                return false
            }
        }
        // Группировка по CategoryKey
        let groupedCat = Dictionary(grouping: filtered) { CategoryKey(icon: $0.icon, color: $0.color, title: $0.title) }
        return groupedCat.map { (key, txs) in
            let total = txs.map { abs($0.amount) }.reduce(0, +)
            let icon = key.icon
            let color = Color(hex: key.color)
            let title = key.title
            return CategoryStat(category: title, total: total, color: color, categoryIcon: icon)
        }.sorted { $0.total > $1.total }
    }
} 
 
