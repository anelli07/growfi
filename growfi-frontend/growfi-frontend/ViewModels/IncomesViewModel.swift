import Foundation
import Combine

class IncomesViewModel: ObservableObject {
    @Published var incomes: [Income] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    weak var walletsVM: WalletsViewModel? = nil // для обновления баланса кошелька
    weak var goalsVM: GoalsViewModel? = nil // для обновления целей
    weak var historyVM: HistoryViewModel? = nil // для обновления истории
    weak var analyticsVM: AnalyticsViewModel? = nil // для обновления аналитики

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    init() {
        fetchIncomes()
    }

    func fetchIncomes() {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.fetchIncomes(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let incomes):
                    self?.incomes = incomes.sorted { $0.id < $1.id }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func createIncome(name: String, icon: String, color: String, categoryId: Int?) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.createIncome(name: name, icon: icon, color: color, categoryId: categoryId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let income):
                    self?.incomes.append(income)
                    // Обновляем аналитику
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    // Handle error silently
                    break
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func updateIncome(id: Int, name: String, icon: String, color: String, description: String?) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.updateIncome(id: id, name: name, icon: icon, color: color, description: description, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let income):
                    if let idx = self?.incomes.firstIndex(where: { $0.id == id }) {
                        self?.incomes[idx] = income
                    }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func assignIncomeToWallet(incomeId: Int, walletId: Int, amount: Double, date: String, comment: String?, categoryId: Int? = nil) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.assignIncomeToWallet(incomeId: incomeId, walletId: walletId, amount: amount, date: date, comment: comment, categoryId: categoryId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let resp):
                    // Обновляем income
                    if let idx = self?.incomes.firstIndex(where: { $0.id == resp.income.id }) {
                        self?.incomes[idx] = resp.income
                    }
                    // Обновляем wallet
                    if let walletIdx = self?.walletsVM?.wallets.firstIndex(where: { $0.id == resp.wallet.id }) {
                        self?.walletsVM?.wallets[walletIdx] = resp.wallet
                    }
                    // Обновляем историю
                    self?.historyVM?.fetchTransactions()
                    // Обновляем аналитику
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func deleteIncome(id: Int) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.deleteIncome(incomeId: id, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.incomes.removeAll { $0.id == id }
                    // Обновляем аналитику
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
} 
