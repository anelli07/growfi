import SwiftUI

struct OperationsView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @EnvironmentObject var walletsVM: WalletsViewModel
    @EnvironmentObject var expensesVM: ExpensesViewModel
    @EnvironmentObject var incomesVM: IncomesViewModel
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @EnvironmentObject var analyticsVM: AnalyticsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var tourManager: AppTourManager
    @Binding var operationsIncomeFrame: CGRect
    @Binding var operationsWalletsFrame: CGRect
    @Binding var operationsGoalsFrame: CGRect
    @Binding var operationsExpensesFrame: CGRect
    @Binding var dragWalletFrames: [CGRect]
    @Binding var dragIncomeFrames: [CGRect]
    @Binding var goalsFrames: [CGRect]
    @Binding var expensesFrames: [CGRect]
    @State private var dragIncomeId: Int? = nil
    @State private var dragWalletId: Int? = nil
    @State private var dragAmount: Double = 0
    @State private var transferAmount: Double = 0
    @State private var transferDate: Date = Date()
    @State private var transferComment: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var editItem: EditableItem? = nil
    @State private var createItem: CreateType? = nil
    @State private var transferItem: TransferType? = nil

    enum CreateType: Identifiable {
        case income, wallet, goal, expense
        var id: String {
            switch self {
            case .income: return "income"
            case .wallet: return "wallet"
            case .goal: return "goal"
            case .expense: return "expense"
            }
        }
    }
    enum EditableItem: Identifiable {
        case wallet(Wallet)
        case income(Income)
        case goal(Goal)
        case expense(Expense)
        var id: String {
            switch self {
            case .wallet(let w): return "wallet_\(w.id)"
            case .income(let i): return "income_\(i.id)"
            case .goal(let g): return "goal_\(g.id)"
            case .expense(let e): return "expense_\(e.id)"
            }
        }
    }

    var incomeTotal: Double { viewModel.incomes.map { $0.amount }.reduce(0, +) }
    var walletTotal: Double { walletsVM.wallets.map { $0.balance }.reduce(0, +) }
    var expenseTotal: Double { Double(expensesVM.expenses.count) } // или 0, если не нужно

    let defaultExpenses: [(name: String, icon: String, color: Color)] = [
        (CategoryType.развлечения.localizedName, CategoryType.развлечения.icon, CategoryType.развлечения.color),
        (CategoryType.связь.localizedName, "phone.fill", .teal),
        (CategoryType.транспорт.localizedName, CategoryType.транспорт.icon, CategoryType.транспорт.color),
        (CategoryType.еда.localizedName, CategoryType.еда.icon, CategoryType.еда.color),
        (CategoryType.продукты.localizedName, CategoryType.продукты.icon, CategoryType.продукты.color),
        (CategoryType.здоровье.localizedName, CategoryType.здоровье.icon, CategoryType.здоровье.color),
        ("Travel".localized, "airplane", .mint),
        ("Clothes".localized, "tshirt.fill", .gray),
        ("Beauty".localized, "scissors", .pink)
    ]

    @State private var showIncome = true
    @State private var showWallets = true
    @State private var showGoals = true
    @State private var showExpenses = true

    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
            VStack(spacing: 12) {
                incomesSection.id("incomesSection")
                walletsSection
                goalsSection
                    expensesSection.id("expensesSection")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            }
            .onChange(of: tourManager.currentStep) { _, newStep in
                if newStep == AppTourStep.operationsExpenses {
                    withAnimation {
                        scrollProxy.scrollTo("expensesSection", anchor: .bottom)
                    }
                }
                if newStep == AppTourStep.dragIncomeToWallet {
                    withAnimation {
                        scrollProxy.scrollTo("incomesSection", anchor: .top)
                    }
                }
                // Скролл наверх при переходе назад с "Расходы" к "Цели"
                if newStep == AppTourStep.operationsGoals {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        scrollProxy.scrollTo("incomesSection", anchor: .top)
                    }
                }
            }
        }
        .onAppear {
            _ = viewModel
            _ = walletsVM
            _ = expensesVM
            _ = incomesVM
            _ = categoriesVM
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("error".localized), message: Text(alertMessage), dismissButton: .default(Text("ok".localized)))
        }
        .sheet(item: $transferItem) { type in
            TransferSheet(
                type: type,
                amount: $transferAmount,
                date: $transferDate,
                comment: $transferComment
            ) { amount, date, comment in
                handleTransfer(amount: amount, date: date, comment: comment)
                transferItem = nil
            }
            .id(UUID())
        }
        .id(AppLanguageManager.shared.currentLanguage)
        .sheet(item: $createItem) { type in
            CreateItemSheet(type: type) { name, sum, icon, color, currency, initial, planPeriod, planAmount, reminderPeriod, selectedWeekday, selectedMonthDay, selectedTime in
                    switch type {
                case .income:
                    let catId: Int? = categoriesVM.incomeCategories.first?.id
                    incomesVM.createIncome(name: name, icon: icon ?? "dollarsign.circle.fill", color: color ?? "#00FF00", categoryId: catId)
                case .wallet:
                    walletsVM.createWallet(name: name, balance: sum, currency: currency, icon: icon ?? "creditcard.fill", color: color ?? "#0000FF")
                case .goal:
                    print("DEBUG: OperationsView - calling createGoal with selectedMonthDay: \(selectedMonthDay ?? -1)")
                    print("DEBUG: OperationsView - calling createGoal with selectedWeekday: \(selectedWeekday ?? -1)")
                    viewModel.createGoal(
                        name: name,
                        targetAmount: sum,
                        currentAmount: initial,
                        currency: currency,
                        icon: icon ?? "leaf.circle.fill",
                        color: color ?? "#00FF00",
                        planPeriod: planPeriod,
                        planAmount: planAmount,
                        reminderPeriod: reminderPeriod,
                        selectedWeekday: selectedWeekday,
                        selectedMonthDay: selectedMonthDay,
                        selectedTime: selectedTime
                    )
                case .expense:
                    let catId: Int? = categoriesVM.expenseCategories.first?.id
                    let walletId: Int? = walletsVM.wallets.first?.id
                    expensesVM.createExpense(name: name, icon: icon ?? "cart.fill", color: color ?? "#FF0000", categoryId: catId, walletId: walletId)
                }
                createItem = nil
            }
            .id(UUID())
        }
        .id(AppLanguageManager.shared.currentLanguage)
        .sheet(item: $editItem) { item in
            EditItemSheet(item: item, viewModel: viewModel) {
                editItem = nil
            }
            .id(item.id)
        }
        .id(AppLanguageManager.shared.currentLanguage)
        .onAppear {
            // Принудительно инициализируем ViewModels при появлении экрана
            _ = viewModel
            _ = walletsVM
            _ = expensesVM
            _ = incomesVM
            _ = categoriesVM
        }
        .onLanguageChange()
    }

    // --- СЕКЦИИ ---
    
    private func handleTransfer(amount: Double, date: Date, comment: String) {
        guard let transferType = transferItem else { return }
        
        switch transferType {
                    case .incomeToWallet(let income, let wallet):
                        guard amount > 0 else {
                            alertMessage = "Введите сумму больше 0"
                            showAlert = true
                            return
                        }
                        incomesVM.assignIncomeToWallet(
                            incomeId: income.id,
                            walletId: wallet.id,
                            amount: amount,
                            date: date.toBackendString(),
                            comment: comment,
                            categoryId: income.category_id
                        )
                    case .walletToGoal(let wallet, let goal):
            guard amount > 0 else {
                alertMessage = "Введите сумму больше 0"
                showAlert = true
                return
            }
            
            // Проверяем, не достигнута ли уже цель
            guard goal.current_amount < goal.target_amount else {
                alertMessage = "goal_already_completed".localized
                showAlert = true
                return
            }
            
            guard amount <= wallet.balance else {
                alertMessage = "Недостаточно средств"
                showAlert = true
                return
            }
            
            // Проверяем, не превысит ли сумма целевую
            let remainingAmount = goal.target_amount - goal.current_amount
            guard amount <= remainingAmount else {
                alertMessage = String(format: "max_amount_to_add".localized, "\(Int(remainingAmount))")
                showAlert = true
                return
            }
                        walletsVM.assignWalletToGoal(
                            walletId: wallet.id,
                            goalId: goal.id,
                            amount: amount,
                            date: date.toBackendString(),
                            comment: comment
                        )
                    case .walletToExpense(let wallet, let expense):
            guard amount > 0 else {
                alertMessage = "Введите сумму больше 0"
                showAlert = true
                return
            }
            guard amount <= wallet.balance else {
                alertMessage = "Недостаточно средств"
                showAlert = true
                return
            }
                        walletsVM.assignWalletToExpense(
                            walletId: wallet.id,
                            expenseId: expense.id,
                            amount: amount,
                            date: date.toBackendString(),
                comment: comment
                        )
                    }
    }

    // --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---
    
    private func showCreateSheet(for type: CreateType) {
        // Просто устанавливаем createItem - sheet откроется автоматически
        createItem = type
    }
    
    private func showTransferSheet(for type: TransferType) {
        // Просто устанавливаем transferItem - sheet откроется автоматически
        transferItem = type
    }

    private var incomesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionToggleHeader(title: "incomes_section".localized, total: "\(Int(incomeTotal)) ₸", isExpanded: .constant(true))
            CategoryGrid {
                Group {
                    ForEach(Array(incomesVM.incomes.enumerated()), id: \.element.id) { idx, income in
                        OperationCategoryCircle(
                            icon: income.icon,
                            color: .green,
                            title: income.name,
                            amount: "\(Int(income.amount ?? 0)) ₸",
                            onDrag: {
                                dragIncomeId = income.id
                                dragAmount = 0
                                return NSItemProvider(object: String(income.id) as NSString)
                            }
                        )
                        .onTapGesture { editItem = .income(income) }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        if dragIncomeFrames.count <= idx {
                                            dragIncomeFrames.append(geo.frame(in: .named("tourRoot")))
                                        } else {
                                            dragIncomeFrames[idx] = geo.frame(in: .named("tourRoot"))
                                        }
                                    }
                                    .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                                        if dragIncomeFrames.count <= idx {
                                            dragIncomeFrames.append(newValue)
                                        } else {
                                            dragIncomeFrames[idx] = newValue
                                        }
                                    }
                            }
                        )
                    }
                    Button(action: {
                        showCreateSheet(for: .income)
                    }) {
                        PlusCategoryCircle()
                    }
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        operationsIncomeFrame = geo.frame(in: .named("tourRoot"))
                    }
                    .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                        operationsIncomeFrame = newValue
                    }
            }
        )
    }

    private var walletGrid: some View {
        ForEach(walletsVM.wallets) { wallet in
            OperationCategoryCircle(
                icon: wallet.iconName ?? "creditcard.fill",
                color: .blue,
                title: wallet.name.localizedIfDefault,
                amount: "\(Int(wallet.balance)) ₸",
                onDrag: {
                    dragWalletId = wallet.id
                    dragAmount = 0
                    return NSItemProvider(object: String(wallet.id) as NSString)
                },
                onDrop: { providers in
                    providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                        if let data = data as? Data,
                           let idString = String(data: data, encoding: .utf8),
                           let incomeId = Int(idString),
                           let income = incomesVM.incomes.first(where: { $0.id == incomeId }) {
                            DispatchQueue.main.async {
                                showTransferSheet(for: .incomeToWallet(income, wallet))
                            }
                        }
                    }
                    return true
                }
            )
            .onTapGesture { editItem = .wallet(wallet) }
        }
    }

    private var expenseGrid: some View {
        ForEach(expensesVM.expenses, id: \.id) { expense in
            OperationCategoryCircle(
                icon: expense.icon,
                color: .red,
                title: expense.name.localizedIfDefault,
                amount: "\(Int(expense.amount)) ₸",
                onDrop: { providers in
                    providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                        if let data = data as? Data,
                           let idString = String(data: data, encoding: .utf8),
                           let walletId = Int(idString),
                           let wallet = walletsVM.wallets.first(where: { $0.id == walletId }) {
                            DispatchQueue.main.async {
                                showTransferSheet(for: .walletToExpense(wallet, expense))
                            }
                        }
                    }
                    return true
                }
            )
            .onTapGesture { editItem = .expense(expense) }
        }
    }

    private var goalGrid: some View {
        ForEach(viewModel.goals) { goal in
            OperationCategoryCircle(
                icon: "leaf.circle.fill",
                color: .green,
                title: goal.name.localizedIfDefault,
                amount: "\(Int(goal.current_amount))/\(Int(goal.target_amount)) ₸",
                onDrop: { providers in
                    providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                        if let data = data as? Data,
                           let idString = String(data: data, encoding: .utf8),
                           let walletId = Int(idString),
                           let wallet = walletsVM.wallets.first(where: { $0.id == walletId }) {
                            DispatchQueue.main.async {
                                showTransferSheet(for: .walletToGoal(wallet, goal))
                            }
                        }
                    }
                    return true
                }
            )
            .onTapGesture { editItem = .goal(goal) }
        }
    }

    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionToggleHeader(title: "wallets_section".localized, total: "\(Int(walletTotal)) ₸", isExpanded: .constant(true))
            CategoryGrid {
                Group {
                    ForEach(Array(walletsVM.wallets.enumerated()), id: \.element.id) { idx, wallet in
                        OperationCategoryCircle(
                            icon: wallet.iconName ?? "creditcard.fill",
                            color: .blue,
                            title: wallet.name.localizedIfDefault,
                            amount: "\(Int(wallet.balance)) ₸",
                            onDrag: {
                                dragWalletId = wallet.id
                                dragAmount = 0
                                return NSItemProvider(object: String(wallet.id) as NSString)
                            },
                            onDrop: { providers in
                                providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                    if let data = data as? Data,
                                       let idString = String(data: data, encoding: .utf8),
                                       let incomeId = Int(idString),
                                       let income = incomesVM.incomes.first(where: { $0.id == incomeId }) {
                                        DispatchQueue.main.async {
                                            showTransferSheet(for: .incomeToWallet(income, wallet))
                                        }
                                    }
                                }
                                return true
                            }
                        )
                        .onTapGesture { editItem = .wallet(wallet) }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        if dragWalletFrames.count <= idx {
                                            dragWalletFrames.append(geo.frame(in: .named("tourRoot")))
                                        } else {
                                            dragWalletFrames[idx] = geo.frame(in: .named("tourRoot"))
                                        }
                                    }
                                    .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                                        if dragWalletFrames.count <= idx {
                                            dragWalletFrames.append(newValue)
                                        } else {
                                            dragWalletFrames[idx] = newValue
                                        }
                                    }
                            }
                        )
                    }
                    Button(action: {
                        showCreateSheet(for: .wallet)
                    }) {
                        PlusCategoryCircle()
                    }
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        operationsWalletsFrame = geo.frame(in: .named("tourRoot"))
                    }
                    .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                        operationsWalletsFrame = newValue
                    }
            }
        )
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionToggleHeader(title: "goals_section".localized, total: "", isExpanded: .constant(true))
            CategoryGrid {
                Group {
                    ForEach(viewModel.goals) { goal in
                        OperationCategoryCircle(
                            icon: "leaf.circle.fill",
                            color: .green,
                            title: goal.name.localizedIfDefault,
                            amount: "\(Int(goal.current_amount))/\(Int(goal.target_amount)) ₸",
                            onDrop: { providers in
                                providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                    if let data = data as? Data,
                                       let idString = String(data: data, encoding: .utf8),
                                       let walletId = Int(idString),
                                       let wallet = walletsVM.wallets.first(where: { $0.id == walletId }) {
                                        DispatchQueue.main.async {
                                            showTransferSheet(for: .walletToGoal(wallet, goal))
                                        }
                                    }
                                }
                                return true
                            }
                        )
                        .onTapGesture { editItem = .goal(goal) }
                    }
                    Button(action: {
                        showCreateSheet(for: .goal)
                    }) {
                        PlusCategoryCircle()
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    if goalsFrames.isEmpty {
                                        goalsFrames.append(geo.frame(in: .named("tourRoot")))
                                    } else {
                                        goalsFrames[0] = geo.frame(in: .named("tourRoot"))
                                    }
                                }
                                .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                                    if goalsFrames.isEmpty {
                                        goalsFrames.append(newValue)
                                    } else {
                                        goalsFrames[0] = newValue
                                    }
                                }
                        }
                    )
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        operationsGoalsFrame = geo.frame(in: .named("tourRoot"))
                    }
                    .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                        operationsGoalsFrame = newValue
                    }
            }
        )
    }

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionToggleHeader(title: "expenses_section".localized, total: "", isExpanded: .constant(true))
            CategoryGrid {
                Group {
                    ForEach(Array(expensesVM.expenses.enumerated()), id: \.element.id) { idx, expense in
                        OperationCategoryCircle(
                            icon: expense.icon,
                            color: .red,
                            title: expense.name.localizedIfDefault,
                            amount: "\(Int(expense.amount)) ₸",
                            onDrop: { providers in
                                providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                    if let data = data as? Data,
                                       let idString = String(data: data, encoding: .utf8),
                                       let walletId = Int(idString),
                                       let wallet = walletsVM.wallets.first(where: { $0.id == walletId }) {
                                        DispatchQueue.main.async {
                                            showTransferSheet(for: .walletToExpense(wallet, expense))
                                        }
                                    }
                                }
                                return true
                            }
                        )
                        .onTapGesture { editItem = .expense(expense) }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        if expensesFrames.count <= idx {
                                            expensesFrames.append(geo.frame(in: .named("tourRoot")))
                                        } else {
                                            expensesFrames[idx] = geo.frame(in: .named("tourRoot"))
                                        }
                                    }
                                    .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                                        if expensesFrames.count <= idx {
                                            expensesFrames.append(newValue)
                                        } else {
                                            expensesFrames[idx] = newValue
                                        }
                                    }
                            }
                        )
                    }
                    Button(action: {
                        showCreateSheet(for: .expense)
                    }) {
                        PlusCategoryCircle()
                    }
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        operationsExpensesFrame = geo.frame(in: .named("tourRoot"))
                    }
                    .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                        operationsExpensesFrame = newValue
                    }
            }
        )
    }

    private struct ExpensesDefaultListView: View {
        let filteredExpenses: [Expense]
        let defaultExpensesList: [(name: String, icon: String, color: Color)]
        @Binding var editItem: OperationsView.EditableItem?
        let allExpenses: [Expense]
        var body: some View {
            ForEach(defaultExpensesList, id: \.name) { def in
                let expense = filteredExpenses.first(where: { $0.name == def.name })
                let amount = 0
                OperationCategoryCircle(
                    icon: def.icon,
                    color: def.color,
                    title: def.name,
                    amount: "\(Int(amount)) ₸"
                )
                .onTapGesture {
                    if let exp = expense, let e = allExpenses.first(where: { $0.id == exp.id }) {
                        editItem = .expense(e)
                    }
                }
            }
        }
    }

    private struct ExpensesCustomListView: View {
        let filteredExpenses: [Expense]
        let defaultExpensesList: [(name: String, icon: String, color: Color)]
        @Binding var editItem: OperationsView.EditableItem?
        let allExpenses: [Expense]
        var body: some View {
            let customExpenses = filteredExpenses.filter { exp in !defaultExpensesList.contains(where: { $0.name == exp.name }) }
            ForEach(customExpenses) { expense in
                let title = expense.name
                let amount = 0
                OperationCategoryCircle(
                    icon: "cart.fill",
                    color: .red,
                    title: title,
                    amount: "\(amount) ₸"
                )
                .onTapGesture {
                    if let e = allExpenses.first(where: { $0.id == expense.id }) {
                        editItem = .expense(e)
                    }
                }
            }
        }
    }
}

// MARK: - Заголовок с кнопкой-стрелкой
struct SectionToggleHeader: View {
    let title: String
    let total: String
    @Binding var isExpanded: Bool

    var body: some View {
        HStack {
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.gray)
            }
            Text(title)
                .font(.headline)
            Spacer()
            Text(total)
                .font(.headline)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Заголовок без стрелки
struct SectionHeader: View {
    let title: String
    let total: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(total)
                .font(.headline)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Общая сетка с белым фоном
struct CategoryGrid<Content: View>: View {
    let content: () -> Content
    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            content()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Плюс-категория
struct PlusCategoryCircle: View {
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .font(.system(size: 20, weight: .medium))
            }
            Text("")
            Text("")
        }
        .frame(width: 56)
    }
}

#if DEBUG
import SwiftUI

struct OperationsView_Previews: PreviewProvider {
    static var previews: some View {
        OperationsView(operationsIncomeFrame: .constant(.zero), operationsWalletsFrame: .constant(.zero), operationsGoalsFrame: .constant(.zero), operationsExpensesFrame: .constant(.zero), dragWalletFrames: .constant([]), dragIncomeFrames: .constant([]), goalsFrames: .constant([]), expensesFrames: .constant([]))
            .environmentObject(GoalsViewModel())
            .environmentObject(WalletsViewModel())
    }
}
#endif
 
