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
        Transaction(id: UUID(), date: Date(), category: "Зарплата", amount: 0, type: .income, note: nil, wallet: "Карта")
    ]
    @Published var wallets: [Wallet] = [
        Wallet(id: 1, name: "Карта", balance: 0),
        Wallet(id: 2, name: "Наличные", balance: 0)
    ]
    @Published var expenses: [Transaction] = [
        Transaction(id: UUID(), date: Date(), category: "Развлечения", amount: 0, type: .expense, note: nil, wallet: "Карта"),
        Transaction(id: UUID(), date: Date(), category: "Связь", amount: 0, type: .expense, note: nil, wallet: "Карта"),
        Transaction(id: UUID(), date: Date(), category: "Транспорт", amount: 0, type: .expense, note: nil, wallet: "Карта"),
        Transaction(id: UUID(), date: Date(), category: "Еда", amount: 0, type: .expense, note: nil, wallet: "Карта"),
        Transaction(id: UUID(), date: Date(), category: "Продукты", amount: 0, type: .expense, note: nil, wallet: "Карта"),
        Transaction(id: UUID(), date: Date(), category: "Здоровье", amount: 0, type: .expense, note: nil, wallet: "Карта"),
        Transaction(id: UUID(), date: Date(), category: "Путешествия", amount: 0, type: .expense, note: nil, wallet: "Карта"),
        Transaction(id: UUID(), date: Date(), category: "Одежда", amount: 0, type: .expense, note: nil, wallet: "Карта"),
        Transaction(id: UUID(), date: Date(), category: "Красота", amount: 0, type: .expense, note: nil, wallet: "Карта")
    ]

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    init() {
        loadUser()
        // goals = []
        // transactions = []
        // incomes, wallets, expenses уже инициализированы выше
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
        // История по умолчанию пустая
        self.transactions = []
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
        incomes[incomeIdx].amount += amount
        wallets[walletIdx].balance += amount
        let tx = Transaction(id: UUID(), date: Date(), category: "Перевод в кошелек", amount: amount, type: .income, note: nil, wallet: wallets[walletIdx].name)
        transactions.append(tx)
    }
    // Drag&Drop: Кошелек -> Цель
    func transferWalletToGoal(walletId: Int, goalId: Int, amount: Double) -> Bool {
        guard let walletIdx = wallets.firstIndex(where: { $0.id == walletId }),
              let goalIdx = goals.firstIndex(where: { $0.id == goalId }) else { return false }
        guard amount > 0, wallets[walletIdx].balance >= amount else { return false }
        wallets[walletIdx].balance -= amount
        goals[goalIdx].current_amount += amount
        let tx = Transaction(id: UUID(), date: Date(), category: "Пополнение цели: \(goals[goalIdx].name)", amount: -abs(amount), type: .expense, note: nil, wallet: wallets[walletIdx].name)
        transactions.append(tx)
        return true
    }
    // Drag&Drop: Кошелек -> Расход
    func transferWalletToExpense(walletId: Int, expenseId: UUID, amount: Double) -> Bool {
        guard let walletIdx = wallets.firstIndex(where: { $0.id == walletId }),
              let expenseIdx = expenses.firstIndex(where: { $0.id == expenseId }) else { return false }
        guard amount > 0, wallets[walletIdx].balance >= amount else { return false }
        wallets[walletIdx].balance -= amount
        expenses[expenseIdx].amount -= amount
        let tx = Transaction(id: UUID(), date: Date(), category: expenses[expenseIdx].category, amount: -abs(amount), type: .expense, note: nil, wallet: wallets[walletIdx].name)
        transactions.append(tx)
        return true
    }

    // Добавление новых элементов
    func addIncome(name: String, amount: Double) {
        let newIncome = Transaction(id: UUID(), date: Date(), category: name, amount: amount, type: .income, note: nil, wallet: "Карта")
        incomes.append(newIncome)
        // Не добавляем в transactions, чтобы не было мусора в истории
    }
    func addWallet(name: String, amount: Double) {
        let newWallet = Wallet(id: (wallets.last?.id ?? 0) + 1, name: name, balance: amount)
        wallets.append(newWallet)
        // Можно добавить Transaction о пополнении кошелька, если нужно
        if amount > 0 {
            let tx = Transaction(id: UUID(), date: Date(), category: "Пополнение кошелька", amount: amount, type: .income, note: nil, wallet: name)
            transactions.append(tx)
        }
    }
    func addGoal(name: String, amount: Double) {
        let newGoal = Goal(id: (goals.last?.id ?? 0) + 1, name: name, target_amount: amount, current_amount: 0, user_id: nil)
        goals.append(newGoal)
        objectWillChange.send()
        // Не добавляем транзакцию, пока не будет пополнения цели
    }
    func addExpense(name: String, amount: Double) {
        let newExpense = Transaction(id: UUID(), date: Date(), category: name, amount: -abs(amount), type: .expense, note: nil, wallet: "Карта")
        expenses.append(newExpense)
        transactions.append(newExpense)
    }

    // Добавление нового расхода и возврат созданного объекта
    func addExpenseAndReturn(name: String) -> Transaction {
        let newExpense = Transaction(id: UUID(), date: Date(), category: name, amount: 0, type: .expense, note: nil, wallet: "Карта")
        expenses.append(newExpense)
        transactions.append(newExpense)
        return newExpense
    }

    // --- Локальное редактирование и удаление ---
    func updateWallet(id: Int, name: String, amount: Double) {
        if let idx = wallets.firstIndex(where: { $0.id == id }) {
            wallets[idx].name = name
            wallets[idx].balance = amount
            objectWillChange.send()
        }
    }
    func deleteWallet(id: Int) {
        wallets.removeAll { $0.id == id }
        objectWillChange.send()
    }
    func updateIncome(id: UUID, name: String, amount: Double) {
        if let idx = incomes.firstIndex(where: { $0.id == id }) {
            incomes[idx].category = name
            incomes[idx].amount = amount
            objectWillChange.send()
        }
    }
    func deleteIncome(id: UUID) {
        incomes.removeAll { $0.id == id }
        objectWillChange.send()
    }
    func updateGoal(id: Int, name: String, amount: Double) {
        if let idx = goals.firstIndex(where: { $0.id == id }) {
            goals[idx].name = name
            goals[idx].current_amount = amount
            objectWillChange.send()
        }
    }
    func deleteGoal(id: Int) {
        goals.removeAll { $0.id == id }
        objectWillChange.send()
    }
    func updateExpense(id: UUID, name: String, amount: Double) {
        if let idx = expenses.firstIndex(where: { $0.id == id }) {
            expenses[idx].category = name
            expenses[idx].amount = -abs(amount)
            objectWillChange.send()
        }
    }
    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
        objectWillChange.send()
    }
} 
