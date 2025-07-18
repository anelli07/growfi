import Foundation
import Combine

class WalletsViewModel: ObservableObject {
    @Published var wallets: [Wallet] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    weak var goalsVM: GoalsViewModel?
    weak var expensesVM: ExpensesViewModel?
    weak var historyVM: HistoryViewModel? = nil
    weak var analyticsVM: AnalyticsViewModel? = nil // для обновления аналитики

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    init() {
        fetchWallets()
    }

    func fetchWallets() {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.fetchWallets(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let wallets):
                    self?.wallets = wallets.sorted { $0.id < $1.id }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func createWallet(name: String, balance: Double, currency: String, icon: String, color: String) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.createWallet(name: name, balance: balance, currency: currency, icon: icon, color: color, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let wallet):
                    self?.wallets.append(wallet)
                    // Обновляем аналитику
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func updateWallet(id: Int, name: String, balance: Double, icon: String, color: String) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.updateWallet(id: id, name: name, balance: balance, icon: icon, color: color, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let wallet):
                    if let idx = self?.wallets.firstIndex(where: { $0.id == id }) {
                        self?.wallets[idx] = wallet
                    }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func assignWalletToGoal(walletId: Int, goalId: Int, amount: Double, date: String, comment: String?) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.assignWalletToGoal(walletId: walletId, goalId: goalId, amount: amount, date: date, comment: comment, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let resp):
                    // Обновляем wallet
                    if let idx = self?.wallets.firstIndex(where: { $0.id == resp.wallet.id }) {
                        self?.wallets[idx] = resp.wallet
                    }
                    // Обновляем goal
                    if let goalIdx = self?.goalsVM?.goals.firstIndex(where: { $0.id == resp.goal.id }) {
                        self?.goalsVM?.goals[goalIdx] = resp.goal
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

    func assignWalletToExpense(walletId: Int, expenseId: Int, amount: Double, date: String, comment: String? = nil) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.assignWalletToExpense(walletId: walletId, expenseId: expenseId, amount: amount, date: date, comment: comment, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let resp):
                    // Обновляем wallet
                    if let idx = self?.wallets.firstIndex(where: { $0.id == resp.wallet.id }) {
                        self?.wallets[idx] = resp.wallet
                    }
                    // Обновляем expense
                    if let expenseIdx = self?.expensesVM?.expenses.firstIndex(where: { $0.id == resp.expense.id }) {
                        self?.expensesVM?.expenses[expenseIdx] = resp.expense
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

    func deleteWallet(id: Int) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.deleteWallet(walletId: id, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.wallets.removeAll { $0.id == id }
                    // Обновляем аналитику
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
} 
