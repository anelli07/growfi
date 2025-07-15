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
            ($0.category ?? "").lowercased().contains(searchText.lowercased()) ||
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


 
