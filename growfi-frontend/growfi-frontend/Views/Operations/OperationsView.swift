import SwiftUI

enum TransferType {
    case incomeToWallet(Income, Wallet)
    case walletToGoal(Wallet, Goal)
    case walletToExpense(Wallet, Expense)
}

struct OperationsView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @EnvironmentObject var walletsVM: WalletsViewModel
    @EnvironmentObject var expensesVM: ExpensesViewModel
    @EnvironmentObject var incomesVM: IncomesViewModel
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @State private var dragIncomeId: Int? = nil
    @State private var dragWalletId: Int? = nil
    @State private var dragAmount: Double = 0
    @State private var showTransferSheet = false
    @State private var transferType: TransferType? = nil
    @State private var transferAmount: Double = 0
    @State private var transferDate: Date = Date()
    @State private var transferComment: String = ""
    @State private var showCreateSheet: Bool = false
    @State private var createType: CreateType? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var editItem: EditableItem? = nil

    enum CreateType { case income, wallet, goal, expense }
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

        return ScrollView {
            VStack(spacing: 12) {
                incomesSection
                walletsSection
                goalsSection
                expensesSection
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
        .onAppear {
    
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("error".localized), message: Text(alertMessage), dismissButton: .default(Text("ok".localized)))
        }
        .sheet(isPresented: $showTransferSheet) {
            if let type = transferType {
                TransferSheet(type: type, amount: $transferAmount, date: $transferDate, comment: $transferComment) { amount, date, comment in
                    switch type {
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
                        walletsVM.assignWalletToGoal(
                            walletId: wallet.id,
                            goalId: goal.id,
                            amount: amount,
                            date: date.toBackendString(),
                            comment: comment
                        )
                    case .walletToExpense(let wallet, let expense):
                
                        walletsVM.assignWalletToExpense(
                            walletId: wallet.id,
                            expenseId: expense.id,
                            amount: amount,
                            date: date.toBackendString(),
                            comment: comment,
                        )
                    }
                    showTransferSheet = false
                }
                .id(UUID())
            }
        }
        .id(AppLanguageManager.shared.currentLanguage)
        .sheet(isPresented: $showCreateSheet) {
            if let type = createType {
                CreateItemSheet(type: type) { name, sum, icon, color, currency in
                    switch type {
                    case .income:
                        let catId: Int? = categoriesVM.incomeCategories.first?.id
                
                        incomesVM.createIncome(name: name, icon: icon ?? "dollarsign.circle.fill", color: color ?? "#00FF00", categoryId: catId)
                    case .wallet:
                        walletsVM.createWallet(name: name, balance: sum, currency: currency, icon: icon ?? "creditcard.fill", color: color ?? "#0000FF")
                    case .goal:
                        viewModel.createGoal(name: name, targetAmount: sum, currency: currency, icon: icon ?? "leaf.circle.fill", color: color ?? "#00FF00")
                    case .expense:
                        let catId: Int? = categoriesVM.expenseCategories.first?.id
                        let walletId: Int? = walletsVM.wallets.first?.id
                
                        expensesVM.createExpense(name: name, icon: icon ?? "cart.fill", color: color ?? "#FF0000", categoryId: catId, walletId: walletId)
                    }
                    showCreateSheet = false
                }
                .id(UUID())
            }
        }
        .id(AppLanguageManager.shared.currentLanguage)
        .sheet(item: $editItem) { item in
            EditItemSheet(item: item, viewModel: viewModel) {
                editItem = nil
            }
            .id(item.id)
        }
        .id(AppLanguageManager.shared.currentLanguage)
        .onLanguageChange()
    }

    // --- СЕКЦИИ ---
    private var incomesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionToggleHeader(title: "incomes_section".localized, total: "\(Int(incomeTotal)) ₸", isExpanded: .constant(true))
            CategoryGrid {
                Group {
                    ForEach(incomesVM.incomes) { income in
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
                    }
                    Button(action: {
                        createType = .income
                        showCreateSheet = true
                    }) {
                        PlusCategoryCircle()
                    }
                }
            }
        }
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
                                transferType = .incomeToWallet(income, wallet)
                                transferAmount = 0
                                transferDate = Date()
                                transferComment = ""
                                showTransferSheet = true
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
                                transferType = .walletToExpense(wallet, expense)
                                transferAmount = 0
                                transferDate = Date()
                                transferComment = ""
                                showTransferSheet = true
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
                                transferType = .walletToGoal(wallet, goal)
                                transferAmount = 0
                                transferDate = Date()
                                transferComment = ""
                                showTransferSheet = true
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
            SectionHeader(title: "wallets_section".localized, total: "\(Int(walletTotal)) ₸")
            CategoryGrid {
                Group {
                    walletGrid
                    Button(action: {
                        createType = .wallet
                        showCreateSheet = true
                    }) {
                        PlusCategoryCircle()
                    }
                }
            }
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "goals_section".localized, total: "")
            CategoryGrid {
                Group {
                    goalGrid
                    Button(action: {
                        createType = .goal
                        showCreateSheet = true
                    }) {
                        PlusCategoryCircle()
                    }
                }
            }
        }
    }

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "expenses_section".localized, total: "\(Int(expenseTotal)) ₸")
            CategoryGrid {
                Group {
                    expenseGrid
                    Button(action: {
                        createType = .expense
                        showCreateSheet = true
                    }) {
                        PlusCategoryCircle()
                    }
                }
            }
        }
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
        OperationsView()
            .environmentObject(GoalsViewModel())
            .environmentObject(WalletsViewModel())
    }
}
#endif
 
