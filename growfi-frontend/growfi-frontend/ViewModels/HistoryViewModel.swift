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

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    func fetchTransactions() {
        guard let token = token, !token.isEmpty else {
            print("[HistoryViewModel] Нет access_token, не делаю fetchTransactions")
            return
        }
        isLoading = true
        error = nil
        print("[HistoryViewModel] fetchTransactions token=\(token.prefix(40))... (len=\(token.count))")
        ApiService.shared.fetchTransactions(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let txs):
                    print("[DEBUG][HistoryViewModel] Получено транзакций с бэка:", txs)
                    self?.allTransactions = txs
                    self?.applyFilters()
                case .failure(let err):
                    print("[DEBUG][HistoryViewModel] Ошибка декодирования или запроса:", err.localizedDescription)
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func applyFilters() {
        let range = periodVM.currentRange
        let filtered = allTransactions.filter { tx in
            tx.date >= range.start && tx.date <= range.end
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
            Calendar.current.startOfDay(for: tx.date)
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

    // Управление периодом теперь через periodVM
}


 
