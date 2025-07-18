import Foundation
import Combine

class ExpensesViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    weak var analyticsVM: AnalyticsViewModel? = nil // для обновления аналитики

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    init() {
        fetchExpenses()
    }

    func fetchExpenses() {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.fetchExpenses(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let expenses):
                    self?.expenses = expenses.sorted { $0.id < $1.id }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func createExpense(name: String, icon: String, color: String, categoryId: Int?, walletId: Int?) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.createExpense(name: name, icon: icon, color: color, categoryId: categoryId, walletId: walletId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let expense):
                    self?.expenses.append(expense)
                    // Обновляем аналитику
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func updateExpense(id: Int, name: String, icon: String, color: String, description: String?) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.updateExpense(id: id, name: name, icon: icon, color: color, description: description, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let tx):
                    if let idx = self?.expenses.firstIndex(where: { $0.id == id }) {
                        self?.expenses[idx] = tx
                    }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func deleteExpense(id: Int) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.deleteExpense(expenseId: id, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.expenses.removeAll { $0.id == id }
                    // Обновляем аналитику
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
} 
