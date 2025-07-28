import Foundation
import Combine

class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var selectedGoalIndex: Int = 0
    @Published var user: User? = nil
    // Удаляю локальный массив транзакций
    // @Published var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var showCreateGoal: Bool = false
    @Published var incomes: [Transaction] = [
        Transaction(
            id: Int(Date().timeIntervalSince1970 * 1000),
            date: Date(),
            type: .income,
            amount: 0,
            note: nil,
            title: "Зарплата",
            icon: "💸",
            color: "#00FF00",
            wallet_name: "Карта",
            wallet_icon: "💳",
            wallet_color: "#0000FF",
            goal_id: nil
        )
    ]
    // Удаляю expenses и все методы, связанные с расходами
    var expensesVM: ExpensesViewModel? = nil
    var incomesVM: IncomesViewModel? = nil
    // Добавляю ссылку на historyVM
    var historyVM: HistoryViewModel?
    weak var analyticsVM: AnalyticsViewModel? = nil // для обновления аналитики

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    init() {
    }

    func fetchUser() {
        guard let token = UserDefaults.standard.string(forKey: "access_token") else { return }
        ApiService.shared.fetchCurrentUser(token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.user = user
                case .failure(let err):
                    // Handle error silently
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
                    // Проверяем завершение целей после загрузки
                    NotificationManager.shared.checkGoalCompletion(goals: self?.goals ?? [])
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func createGoal(name: String, targetAmount: Double, currentAmount: Double, currency: String = "₸", icon: String = "leaf.circle.fill", color: String = "#00FF00", planPeriod: PlanPeriod? = nil, planAmount: Double? = nil, reminderPeriod: PlanPeriod? = nil, selectedWeekday: Int? = nil, selectedMonthDay: Int? = nil, selectedTime: Date? = nil) {
        print("createGoal debug:", reminderPeriod?.rawValue as Any, selectedWeekday as Any, selectedMonthDay as Any, selectedTime as Any)
        print("DEBUG: GoalsViewModel - selectedMonthDay received: \(selectedMonthDay ?? -1)")
        guard let token = token else { return }
        isLoading = true
        // Создаём Goal локально с планом и настройками уведомлений
        ApiService.shared.createGoal(name: name, targetAmount: targetAmount, currentAmount: currentAmount, currency: currency, icon: icon, color: color, planPeriod: planPeriod?.rawValue, planAmount: planAmount, reminderPeriod: reminderPeriod?.rawValue, selectedWeekday: selectedWeekday, selectedMonthDay: selectedMonthDay, selectedTime: selectedTime != nil ? timeString(selectedTime!) : nil, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(var goal):
                    goal.planPeriod = planPeriod
                    goal.planAmount = planAmount
                    goal.reminderPeriod = reminderPeriod?.rawValue
                    goal.selectedWeekday = selectedWeekday
                    goal.selectedMonthDay = selectedMonthDay
                    goal.selectedTime = selectedTime != nil ? self?.timeString(selectedTime!) : nil
                    self?.goals.append(goal)
                    NotificationManager.shared.schedulePersonalGoalReminder(goal: goal)
                    // Проверяем завершение целей после создания
                    NotificationManager.shared.checkGoalCompletion(goals: self?.goals ?? [])
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func updateGoal(goal: Goal, icon: String = "leaf.circle.fill", color: String = "#00FF00", planPeriod: PlanPeriod? = nil, planAmount: Double? = nil, reminderPeriod: PlanPeriod? = nil, selectedWeekday: Int? = nil, selectedMonthDay: Int? = nil, selectedTime: Date? = nil) {
        guard let token = token else { return }
        isLoading = true
        var updatedGoal = goal
        updatedGoal.planPeriod = planPeriod
        updatedGoal.planAmount = planAmount
        updatedGoal.reminderPeriod = reminderPeriod?.rawValue
        updatedGoal.selectedWeekday = selectedWeekday
        updatedGoal.selectedMonthDay = selectedMonthDay
        updatedGoal.selectedTime = selectedTime != nil ? timeString(selectedTime!) : nil
        ApiService.shared.updateGoal(goal: updatedGoal, icon: icon, color: color, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let updatedGoal):
                    if let idx = self?.goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                        self?.goals[idx] = updatedGoal
                    }
                    NotificationManager.shared.schedulePersonalGoalReminder(goal: updatedGoal)
                    // Проверяем завершение целей после обновления
                    NotificationManager.shared.checkGoalCompletion(goals: self?.goals ?? [])
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
                    // Сбрасываем флаг завершения при удалении цели
                    NotificationManager.shared.resetGoalCompletionFlag(goalId: goalId)
                    // Обновляем аналитику после удаления цели
                    self?.analyticsVM?.fetchTransactions()
                case .failure(let err):
                    print("Error deleting goal: \(err.localizedDescription)")
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func loadTransactions() {
        // История по умолчанию пустая
        // self.transactions = [] // Удалено
    }

    var userName: String {
        user?.full_name ?? "Guest".localized
    }

    var todayTransactions: [Transaction] {
        guard let historyVM = historyVM else { return [] }
        let calendar = Calendar.current
        return historyVM.transactions.filter { calendar.isDateInToday($0.date) }
    }

    var todayExpense: Double {
        guard let historyVM = historyVM else { return 0 }
        let calendar = Calendar.current
        return historyVM.transactions
            .filter { ($0.type == .expense || $0.type == .goal_transfer) && calendar.isDateInToday($0.date) }
            .map { abs($0.amount) }
            .reduce(0, +)
    }

    // Drag&Drop: Доход -> Кошелек
    func transferIncomeToWallet(incomeId: Int, walletId: Int, amount: Double, wallets: inout [Wallet]) {
        guard let incomeIdx = incomes.firstIndex(where: { $0.id == incomeId }),
              let walletIdx = wallets.firstIndex(where: { $0.id == walletId }) else { return }
        var newIncomes = incomes
        newIncomes[incomeIdx].amount += amount
        incomes = newIncomes
        wallets[walletIdx].balance += amount
        let wallet = wallets[walletIdx]
        var incomeTitle = "Доход"
        if let income = incomesVM?.incomes.first(where: { $0.id == incomeId }) {
            incomeTitle = income.name
        }
        _ = Transaction(
            id: Int(Date().timeIntervalSince1970 * 1000),
            date: Date(),
            type: .income,
            amount: amount,
            note: nil,
            title: incomeTitle, // <-- теперь название дохода
            icon: wallet.iconName ?? "💳",
            color: wallet.colorHex ?? "#0000FF",
            wallet_name: wallet.name,
            wallet_icon: wallet.iconName,
            wallet_color: wallet.colorHex,
            goal_id: nil
        )
        // Удаляю все transactions.append(tx), removeAll, и т.д. в transferWalletToGoal, transferWalletToExpense, transferIncomeToWallet и других местах
    }
    // Drag&Drop: Кошелек -> Цель
    func transferWalletToGoal(walletId: Int, goalId: Int, amount: Double, wallets: inout [Wallet]) -> Bool {
        guard let walletIdx = wallets.firstIndex(where: { $0.id == walletId }),
              let goalIdx = goals.firstIndex(where: { $0.id == goalId }) else { return false }
        
        let goal = goals[goalIdx]
        let wallet = wallets[walletIdx]
        
        // Проверяем базовые условия
        guard amount > 0 else { return false }
        guard wallet.balance >= amount else { return false }
        
        // Проверяем, не достигнута ли уже цель
        guard goal.current_amount < goal.target_amount else { return false }
        
        // Проверяем, не превысит ли сумма целевую
        let remainingAmount = goal.target_amount - goal.current_amount
        guard amount <= remainingAmount else { return false }
        
        wallets[walletIdx].balance -= amount
        goals[goalIdx].current_amount += amount
        
        // Отмечаем, что цель была пополнена
        NotificationManager.shared.markGoalAsFunded(goal: goal, amount: amount)
        _ = Transaction(
            id: Int(Date().timeIntervalSince1970 * 1000),
            date: Date(),
            type: .goal,
            amount: -abs(amount),
            note: nil,
            title: "Пополнение цели: \(goal.name)",
            icon: goal.icon,
            color: goal.color,
            wallet_name: wallet.name,
            wallet_icon: wallet.iconName,
            wallet_color: wallet.colorHex,
            goal_id: goal.id // добавлено
        )
        // Удаляю все transactions.append(tx), removeAll, и т.д. в transferWalletToGoal, transferWalletToExpense, transferIncomeToWallet и других местах
        return true
    }
    // Drag&Drop: Кошелек -> Расход
    func transferWalletToExpense(walletId: Int, expenseId: Int, amount: Double, wallets: inout [Wallet]) -> Bool {
        guard let walletIdx = wallets.firstIndex(where: { $0.id == walletId }) else { return false }
        guard amount > 0, wallets[walletIdx].balance >= amount else { return false }
        wallets[walletIdx].balance -= amount
        let wallet = wallets[walletIdx]
        var expenseTitle = "Расход"
        if let expense = expensesVM?.expenses.first(where: { $0.id == expenseId }) {
            expenseTitle = expense.name
        }
        _ = Transaction(
            id: Int(Date().timeIntervalSince1970 * 1000),
            date: Date(),
            type: .expense,
            amount: -abs(amount),
            note: nil,
            title: expenseTitle, // <-- теперь название расхода
            icon: "💸",
            color: "#FF0000",
            wallet_name: wallet.name,
            wallet_icon: wallet.iconName,
            wallet_color: wallet.colorHex,
            goal_id: nil
        )
        // Удаляю все transactions.append(tx), removeAll, и т.д. в transferWalletToGoal, transferWalletToExpense, transferIncomeToWallet и других местах
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
            // В Transaction нет category, только title
            income.amount = amount
            // title менять не будем, если нужно — добавь параметр
            var newIncomes = incomes
            newIncomes[idx] = income
            incomes = newIncomes
        }
    }
    func deleteIncome(id: Int) {
        incomes.removeAll { $0.id == id }
    }
    func updateGoal(id: Int, name: String, amount: Double, targetAmount: Double) {
        if let idx = goals.firstIndex(where: { $0.id == id }) {
            var goal = goals[idx]
            goal.name = name
            goal.current_amount = amount
            goal.target_amount = targetAmount
            goals[idx] = goal
        }
    }
    // Удаляю методы updateExpense и deleteExpense, связанные с expenses

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
} 
