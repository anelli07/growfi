import Foundation
import Combine

class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var selectedGoalIndex: Int = 0
    @Published var user: User? = nil
    @Published var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var showCreateGoal: Bool = false
    @Published var incomes: [Transaction] = [
        Transaction(id: Int(Date().timeIntervalSince1970 * 1000), date: Date(), category: "Зарплата", amount: 0, type: .income, note: nil, wallet: "Карта")
    ]
    // Удаляю expenses и все методы, связанные с расходами

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    init() {
    }

    func fetchUser() {
        guard let token = UserDefaults.standard.string(forKey: "access_token") else { print("[fetchUser] Нет access_token"); return }
        print("[fetchUser] access_token:", token)
        ApiService.shared.fetchCurrentUser(token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    print("[fetchUser] User from API:", user)
                    self?.user = user
                case .failure(let err):
                    print("[fetchUser] Ошибка:", err.localizedDescription)
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func fetchGoals() {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.fetchGoals(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let goals):
                    self?.goals = goals.sorted { $0.id < $1.id }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func createGoal(name: String, targetAmount: Double, currency: String = "₸", icon: String = "leaf.circle.fill", color: String = "#00FF00") {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.createGoal(name: name, targetAmount: targetAmount, currency: currency, icon: icon, color: color, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let goal):
                    self?.goals.append(goal)
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func updateGoal(goal: Goal, currency: String = "₸", icon: String = "leaf.circle.fill", color: String = "#00FF00") {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.updateGoal(goal: goal, currency: currency, icon: icon, color: color, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let updatedGoal):
                    if let idx = self?.goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                        self?.goals[idx] = updatedGoal
                    }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func deleteGoal(goalId: Int) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.deleteGoal(goalId: goalId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.goals.removeAll { $0.id == goalId }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func loadTransactions() {
        // История по умолчанию пустая
        self.transactions = []
    }

    var userName: String {
        user?.full_name ?? "Гость"
    }

    var todayTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { calendar.isDateInToday($0.date) }
    }

    var todayExpense: Double {
        todayTransactions.filter { $0.type == .expense }.map { abs($0.amount) }.reduce(0, +)
    }

    // Drag&Drop: Доход -> Кошелек
    func transferIncomeToWallet(incomeId: Int, walletId: Int, amount: Double, wallets: inout [Wallet]) {
        guard let incomeIdx = incomes.firstIndex(where: { $0.id == incomeId }),
              let walletIdx = wallets.firstIndex(where: { $0.id == walletId }) else { return }
        incomes[incomeIdx].amount += amount
        wallets[walletIdx].balance += amount
        let tx = Transaction(id: Int(Date().timeIntervalSince1970 * 1000), date: Date(), category: "Перевод в кошелек", amount: amount, type: .income, note: nil, wallet: wallets[walletIdx].name)
        transactions.append(tx)
    }
    // Drag&Drop: Кошелек -> Цель
    func transferWalletToGoal(walletId: Int, goalId: Int, amount: Double, wallets: inout [Wallet]) -> Bool {
        guard let walletIdx = wallets.firstIndex(where: { $0.id == walletId }),
              let goalIdx = goals.firstIndex(where: { $0.id == goalId }) else { return false }
        guard amount > 0, wallets[walletIdx].balance >= amount else { return false }
        wallets[walletIdx].balance -= amount
        goals[goalIdx].current_amount += amount
        let tx = Transaction(id: Int(Date().timeIntervalSince1970 * 1000), date: Date(), category: "Пополнение цели: \(goals[goalIdx].name)", amount: -abs(amount), type: .expense, note: nil, wallet: wallets[walletIdx].name)
        transactions.append(tx)
        return true
    }
    // Drag&Drop: Кошелек -> Расход
    func transferWalletToExpense(walletId: Int, expenseId: Int, amount: Double, wallets: inout [Wallet]) -> Bool {
        // Здесь можно реализовать нужную логику, например, просто уменьшать баланс кошелька и создавать транзакцию
        guard let walletIdx = wallets.firstIndex(where: { $0.id == walletId }) else { return false }
        guard amount > 0, wallets[walletIdx].balance >= amount else { return false }
        wallets[walletIdx].balance -= amount
        let tx = Transaction(id: Int(Date().timeIntervalSince1970 * 1000), date: Date(), category: "Расход", amount: -abs(amount), type: .expense, note: nil, wallet: wallets[walletIdx].name)
        transactions.append(tx)
        return true
    }

    // --- Локальное редактирование и удаление ---
    func updateWallet(id: Int, name: String, amount: Double, wallets: inout [Wallet]) {
        if let idx = wallets.firstIndex(where: { $0.id == id }) {
            var wallet = wallets[idx]
            wallet.name = name
            wallet.balance = amount
            wallets[idx] = wallet
        }
    }
    func deleteWallet(id: Int, wallets: inout [Wallet]) {
        wallets.removeAll { $0.id == id }
    }
    func updateIncome(id: Int, name: String, amount: Double) {
        if let idx = incomes.firstIndex(where: { $0.id == id }) {
            var income = incomes[idx]
            income.category = name
            income.amount = amount
            incomes[idx] = income
        }
    }
    func deleteIncome(id: Int) {
        incomes.removeAll { $0.id == id }
    }
    func updateGoal(id: Int, name: String, amount: Double) {
        if let idx = goals.firstIndex(where: { $0.id == id }) {
            var goal = goals[idx]
            goal.name = name
            goal.current_amount = amount
            goals[idx] = goal
        }
    }
    func deleteGoal(id: Int) {
        goals.removeAll { $0.id == id }
    }
    func updateExpense(id: Int, name: String, amount: Double) {
        if let idx = transactions.firstIndex(where: { $0.id == id }) {
            var tx = transactions[idx]
            tx.category = name
            tx.amount = -abs(amount)
            transactions[idx] = tx
        }
    }
    func deleteExpense(id: Int) {
        transactions.removeAll { $0.id == id }
    }
} 
