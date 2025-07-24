import Foundation
import SwiftUI

class HistoryViewModel: ObservableObject {
    @Published var periodVM = PeriodSelectionViewModel()
    @Published var transactions: [Transaction] = []
    @Published var searchText: String = ""
    @Published var filteredDays: [TransactionDay] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    private var allTransactions: [Transaction] = []
    weak var analyticsVM: AnalyticsViewModel? = nil // для обновления аналитики

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    func fetchTransactions() {
        guard let token = token, !token.isEmpty else { return }
        isLoading = true
        error = nil

        ApiService.shared.fetchTransactions(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let txs):
                    print("FETCHED TRANSACTIONS:", txs)
                    self?.allTransactions = txs
                    self?.applyFilters()
                    print("AFTER FILTER:", self?.transactions ?? [])
                    self?.analyticsVM?.updateFromHistory(self?.allTransactions ?? [])
                case .failure(let err):
                    print("FETCH ERROR:", err)
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func applyFilters() {
        let range = periodVM.currentRange
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: range.start)
        let endDay = calendar.startOfDay(for: range.end)
        let filtered = allTransactions.filter { tx in
            let txDay = calendar.startOfDay(for: tx.date)
            return txDay >= startDay && txDay <= endDay
        }
        // Поиск по заметке и категории
        let searched = searchText.isEmpty ? filtered : filtered.filter {
            $0.title.lowercased().contains(searchText.lowercased()) ||
            ($0.note ?? "").lowercased().contains(searchText.lowercased())
        }
        // Убираем транзакции с amount == 0 (шаблоны)
        let nonZero = searched.filter { $0.amount != 0 }
        // Группировка по дням
        let grouped = Dictionary(grouping: nonZero) { tx in
            calendar.startOfDay(for: tx.date)
        }
        .map { (date, txs) in
            TransactionDay(id: Int(date.timeIntervalSince1970), date: date, transactions: txs)
        }
        .sorted { $0.date > $1.date }
        DispatchQueue.main.async {
            self.filteredDays = grouped
            self.transactions = nonZero
        }
    }

    func updateSearch(text: String) {
        searchText = text
        applyFilters()
    }
    
    func deleteTransaction(id: Int) {
        guard let token = token else { return }
        print("[HistoryViewModel] Starting transaction deletion for ID: \(id)")
        
        ApiService.shared.deleteTransaction(transactionId: id, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("[HistoryViewModel] Transaction deleted successfully, removing from local arrays")
                    // Удаляем из всех массивов
                    self?.allTransactions.removeAll { $0.id == id }
                    self?.transactions.removeAll { $0.id == id }
                    // Обновляем отфильтрованные дни
                    self?.applyFilters()
                    // Обновляем аналитику
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    print("[HistoryViewModel] Transaction deletion failed: \(err.localizedDescription)")
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    // Управление периодом теперь через periodVM
}


 
