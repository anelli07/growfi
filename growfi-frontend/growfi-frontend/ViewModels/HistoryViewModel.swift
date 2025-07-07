import Foundation
import SwiftUI

class HistoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var searchText: String = ""
    @Published var selectedPeriod: PeriodType = .month
    @Published var filteredDays: [TransactionDay] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    private var allTransactions: [Transaction] = []

    init() {
        fetchTransactionsFromApi()
    }

    func fetchTransactionsFromApi() {
        isLoading = true
        error = nil
        let token = UserDefaults.standard.string(forKey: "access_token") ?? ""
        ApiService.shared.fetchTransactions(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let txs):
                    self?.allTransactions = txs
                    self?.applyFilters()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func applyFilters() {
        // Фильтрация по периоду (заглушка: только месяц)
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
        // Поиск по заметке и категории
        let searched = searchText.isEmpty ? filtered : filtered.filter {
            ($0.category.lowercased().contains(searchText.lowercased()) ||
             ($0.note ?? "").lowercased().contains(searchText.lowercased()))
        }
        // Группировка по дням
        let grouped = Dictionary(grouping: searched) { tx in
            Calendar.current.startOfDay(for: tx.date)
        }
        .map { (date, txs) in
            TransactionDay(date: date, transactions: txs)
        }
        .sorted { $0.date > $1.date }
        DispatchQueue.main.async {
            self.filteredDays = grouped
            self.transactions = searched
        }
    }

    func updateSearch(text: String) {
        searchText = text
        applyFilters()
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
}


