import Foundation
import Combine

class IncomesViewModel: ObservableObject {
    @Published var incomes: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

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
                    self?.incomes = incomes
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func createIncome(name: String, icon: String, color: String, description: String?) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.createIncome(name: name, icon: icon, color: color, description: description, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let income):
                    self?.incomes.append(income)
                case .failure(let err):
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
                    if let idx = self?.incomes.firstIndex(where: { $0.id == income.id }) {
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
                case .success(let updatedIncome):
                    if let idx = self?.incomes.firstIndex(where: { $0.id == updatedIncome.id }) {
                        self?.incomes[idx] = updatedIncome
                    }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func deleteIncome(id: UUID) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.deleteIncome(incomeId: id, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.incomes.removeAll { $0.id == id }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
} 
