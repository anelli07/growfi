import Foundation
import Combine

class WalletsViewModel: ObservableObject {
    @Published var wallets: [Wallet] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

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
                    self?.wallets = wallets
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
                    if let idx = self?.wallets.firstIndex(where: { $0.id == wallet.id }) {
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
                case .success(let wallet):
                    if let idx = self?.wallets.firstIndex(where: { $0.id == wallet.id }) {
                        self?.wallets[idx] = wallet
                    }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func assignWalletToExpense(walletId: Int, expenseId: Int, amount: Double, date: String, comment: String?) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.assignWalletToExpense(walletId: walletId, expenseId: expenseId, amount: amount, date: date, comment: comment, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let wallet):
                    if let idx = self?.wallets.firstIndex(where: { $0.id == wallet.id }) {
                        self?.wallets[idx] = wallet
                    }
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
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
} 