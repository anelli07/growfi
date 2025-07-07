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
        Transaction(id: UUID(), date: Date(), category: "Зарплата", amount: 40000, type: .income, note: nil, wallet: "")
    ]
    @Published var wallets: [Wallet] = [
        Wallet(id: 1, name: "Карта", balance: 36950),
        Wallet(id: 2, name: "Наличные", balance: 0)
    ]
    @Published var expenses: [Transaction] = [
        Transaction(id: UUID(), date: Date(), category: "Продукты", amount: -3050, type: .expense, note: nil, wallet: "")
    ]

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    init() {
        loadUser()
        fetchGoals()
        loadTransactions()
    }

    func loadUser() {
        // Заглушка: потом заменить на API
        self.user = User(id: "1", name: "Аня", email: "anya@email.com")
    }

    func fetchGoals() {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.fetchGoals(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let goals):
                    self?.goals = goals
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func createGoal(name: String, targetAmount: Double) {
        guard let token = token else { return }
        isLoading = true
        let newGoal = Goal(id: 0, name: name, target_amount: targetAmount, current_amount: 0, user_id: nil)
        ApiService.shared.createGoal(goal: newGoal, token: token) { [weak self] result in
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

    func updateGoal(goal: Goal) {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.updateGoal(goal: goal, token: token) { [weak self] result in
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
        // Заглушка: потом заменить на API
        let today = Date()
        self.transactions = [
            Transaction(id: UUID(), date: today, category: "Продукты", amount: -2000, type: .expense, note: "Магазин", wallet: "Карта"),
            Transaction(id: UUID(), date: today, category: "Кофе", amount: -1200, type: .expense, note: nil, wallet: "Карта"),
            Transaction(id: UUID(), date: today, category: "To Goal", amount: 5000, type: .income, note: "Пополнение цели", wallet: "Карта")
        ]
    }

    var userName: String {
        user?.name ?? "Гость"
    }

    var todayTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { calendar.isDateInToday($0.date) }
    }

    var todayExpense: Double {
        todayTransactions.filter { $0.type == .expense }.map { abs($0.amount) }.reduce(0, +)
    }

    // Drag&Drop: Доход -> Кошелек
    func transferIncomeToWallet(incomeId: UUID, walletId: Int, amount: Double) {
        guard let incomeIdx = incomes.firstIndex(where: { $0.id == incomeId }),
              let walletIdx = wallets.firstIndex(where: { $0.id == walletId }) else { return }
        // Просто увеличиваем сумму кошелька, доход не исчезает
        incomes[incomeIdx].amount += amount
        wallets[walletIdx].balance += amount
    }
    // Drag&Drop: Кошелек -> Цель
    func transferIncomeToWallet(incomeId: UUID, walletId: Int) {
        guard let incomeIdx = incomes.firstIndex(where: { $0.id == incomeId }),
              let walletIdx = wallets.firstIndex(where: { $0.id == walletId }) else { return }
        
        guard incomes[incomeIdx].amount >= 0.01 else { return }
        
        incomes[incomeIdx].amount -= 0.01
        wallets[walletIdx].balance += 0.01

        if incomes[incomeIdx].amount <= 0.01 {
            incomes.remove(at: incomeIdx)
        }
    }
    // Drag&Drop: Кошелек -> Расход
    func transferWalletToExpense(walletId: Int, expenseId: UUID, amount: Double) -> Bool {
        guard let walletIdx = wallets.firstIndex(where: { $0.id == walletId }),
              let expenseIdx = expenses.firstIndex(where: { $0.id == expenseId }) else { return false }
        guard amount > 0, wallets[walletIdx].balance >= amount else { return false }
        wallets[walletIdx].balance -= amount
        expenses[expenseIdx].amount -= amount
        return true
    }
    // Drag&Drop: Кошелек -> Цель
    func transferWalletToGoal(walletId: Int, goalId: Int, amount: Double) -> Bool {
        guard let walletIdx = wallets.firstIndex(where: { $0.id == walletId }),
              let goalIdx = goals.firstIndex(where: { $0.id == goalId }) else { return false }
        guard amount > 0, wallets[walletIdx].balance >= amount else { return false }
        wallets[walletIdx].balance -= amount
        goals[goalIdx].current_amount += amount
        return true
    }

    // Добавление новых элементов
    func addIncome(name: String, amount: Double) {
        let newIncome = Transaction(id: UUID(), date: Date(), category: name, amount: amount, type: .income, note: nil, wallet: "")
        incomes.append(newIncome)
    }
    func addWallet(name: String, amount: Double) {
        let newWallet = Wallet(id: (wallets.last?.id ?? 0) + 1, name: name, balance: amount)
        wallets.append(newWallet)
    }
    func addGoal(name: String, amount: Double) {
        let newGoal = Goal(id: (goals.last?.id ?? 0) + 1, name: name, target_amount: amount, current_amount: 0, user_id: nil)
        goals.append(newGoal)
        objectWillChange.send()
    }
    func addExpense(name: String, amount: Double) {
        let newExpense = Transaction(id: UUID(), date: Date(), category: name, amount: -abs(amount), type: .expense, note: nil, wallet: "")
        expenses.append(newExpense)
    }

    // Добавление нового расхода и возврат созданного объекта
    func addExpenseAndReturn(name: String) -> Transaction {
        let newExpense = Transaction(id: UUID(), date: Date(), category: name, amount: 0, type: .expense, note: nil, wallet: "")
        expenses.append(newExpense)
        return newExpense
    }
} 
