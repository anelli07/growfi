import SwiftUI

enum TransferType {
    case incomeToWallet(Transaction, Wallet)
    case walletToGoal(Wallet, Goal)
    case walletToExpense(Wallet, Transaction)
}

struct OperationsView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @EnvironmentObject var walletsVM: WalletsViewModel
    @EnvironmentObject var expensesVM: ExpensesViewModel
    @State private var dragIncomeId: UUID? = nil
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
        case income(Transaction)
        case goal(Goal)
        case expense(Transaction)
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
    var expenseTotal: Double { expensesVM.expenses.map { abs($0.amount) }.reduce(0, +) }

    let defaultExpenses: [(name: String, icon: String, color: Color)] = [
        ("Развлечения", CategoryType.from(name: "Развлечения").icon, CategoryType.from(name: "Развлечения").color),
        ("Связь", "phone.fill", .teal),
        ("Транспорт", CategoryType.from(name: "Транспорт").icon, CategoryType.from(name: "Транспорт").color),
        ("Еда", CategoryType.from(name: "Еда").icon, CategoryType.from(name: "Еда").color),
        ("Продукты", CategoryType.from(name: "Продукты").icon, CategoryType.from(name: "Продукты").color),
        ("Здоровье", CategoryType.from(name: "Здоровье").icon, CategoryType.from(name: "Здоровье").color),
        ("Путешествия", "airplane", .mint),
        ("Одежда", "tshirt.fill", .gray),
        ("Красота", "scissors", .pink)
    ]

    @State private var showIncome = true
    @State private var showWallets = true
    @State private var showGoals = true
    @State private var showExpenses = true

    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                incomesSection
                walletsSection
                goalsSection
                expensesSection
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showTransferSheet) {
            if let type = transferType {
                TransferSheet(type: type, amount: $transferAmount, date: $transferDate, comment: $transferComment) { amount, date, comment in
                    switch type {
                    case .incomeToWallet(let income, let wallet):
                        viewModel.transferIncomeToWallet(incomeId: income.id, walletId: wallet.id, amount: amount, wallets: &walletsVM.wallets)
                    case .walletToGoal(let wallet, let goal):
                        let ok = viewModel.transferWalletToGoal(walletId: wallet.id, goalId: goal.id, amount: amount, wallets: &walletsVM.wallets)
                        if !ok {
                            alertMessage = "Недостаточно денег в кошельке"
                            showAlert = true
                        }
                    case .walletToExpense(let wallet, let expense):
                        let ok = viewModel.transferWalletToExpense(walletId: wallet.id, expenseId: expense.id, amount: amount, wallets: &walletsVM.wallets, expenses: &expensesVM.expenses)
                        if !ok {
                            alertMessage = "Недостаточно денег в кошельке"
                            showAlert = true
                        }
                    }
                    showTransferSheet = false
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            if let type = createType {
                CreateItemSheet(type: type) { name, sum, icon, color, currency in
                    switch type {
                    case .income:
                        viewModel.addIncome(name: name, amount: sum)
                    case .wallet:
                        viewModel.addWallet(name: name, amount: sum, wallets: &walletsVM.wallets)
                    case .goal:
                        viewModel.addGoal(name: name, amount: sum)
                    case .expense:
                        viewModel.addExpense(name: name, amount: sum, expenses: &expensesVM.expenses)
                    }
                    showCreateSheet = false
                }
            }
        }
        .sheet(item: $editItem) { item in
            EditItemSheet(item: item, viewModel: viewModel) {
                editItem = nil
            }
        }
    }

    // --- СЕКЦИИ ---
    private var incomesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionToggleHeader(title: "Доходы", total: "\(Int(incomeTotal)) ₸", isExpanded: .constant(true))
            CategoryGrid {
                Group {
                    ForEach(viewModel.incomes) { income in
                        OperationCategoryCircle(icon: "dollarsign.circle.fill", color: .green, title: income.category, amount: "\(Int(income.amount)) ₸")
                            .onTapGesture { editItem = .income(income) }
                            .onDrag {
                                dragIncomeId = income.id
                                dragAmount = income.amount
                                return NSItemProvider(object: income.id.uuidString as NSString)
                            } preview: {
                                ZStack {
                                    Circle().fill(Color.green).frame(width: 48, height: 48)
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .medium))
                                }
                            }
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

    private var walletsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "Кошельки", total: "\(Int(walletTotal)) ₸")
            CategoryGrid {
                Group {
                    ForEach(walletsVM.wallets) { wallet in
                        OperationCategoryCircle(icon: "creditcard.fill", color: .blue, title: wallet.name, amount: "\(Int(wallet.balance)) ₸")
                            .onTapGesture { editItem = .wallet(wallet) }
                            .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                                providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                    if let data = data as? Data, let idString = String(data: data, encoding: .utf8), let incomeUUID = UUID(uuidString: idString), let income = viewModel.incomes.first(where: { $0.id == incomeUUID }) {
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
                            .onDrag {
                                dragWalletId = wallet.id
                                dragAmount = 0
                                return NSItemProvider(object: String(wallet.id) as NSString)
                            } preview: {
                                ZStack {
                                    Circle().fill(Color.blue).frame(width: 48, height: 48)
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .medium))
                                }
                            }
                    }
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
            SectionHeader(title: "Цели", total: "")
            CategoryGrid {
                Group {
                    ForEach(viewModel.goals) { goal in
                        OperationCategoryCircle(
                            icon: "leaf.circle.fill",
                            color: .green,
                            title: goal.name,
                            amount: "\(Int(goal.current_amount))/\(Int(goal.target_amount)) ₸"
                        )
                        .onTapGesture { editItem = .goal(goal) }
                        .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                            providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                if let data = data as? Data, let idString = String(data: data, encoding: .utf8), let walletId = Int(idString), let wallet = walletsVM.wallets.first(where: { $0.id == walletId }) {
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
                    }
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
            SectionHeader(title: "Расходы", total: "\(Int(expenseTotal)) ₸")
            CategoryGrid {
                Group {
                    ForEach(defaultExpenses, id: \.name) { def in
                        let expense = expensesVM.expenses.first(where: { $0.category == def.name })
                        let amount = expense.map { abs($0.amount) } ?? 0
                        OperationCategoryCircle(
                            icon: def.icon,
                            color: def.color,
                            title: def.name,
                            amount: "\(Int(amount)) ₸"
                        )
                        .onTapGesture {
                            if let exp = expense {
                                editItem = .expense(exp)
                            } else {
                                let newExp = viewModel.addExpenseAndReturn(name: def.name, expenses: &expensesVM.expenses)
                                editItem = .expense(newExp)
                            }
                        }
                        .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                            providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                if let data = data as? Data, let idString = String(data: data, encoding: .utf8), let walletId = Int(idString), let wallet = walletsVM.wallets.first(where: { $0.id == walletId }) {
                                    DispatchQueue.main.async {
                                        let exp = expense ?? viewModel.addExpenseAndReturn(name: def.name, expenses: &expensesVM.expenses)
                                        transferType = .walletToExpense(wallet, exp)
                                        transferAmount = 0
                                        transferDate = Date()
                                        transferComment = ""
                                        showTransferSheet = true
                                    }
                                }
                            }
                            return true
                        }
                    }
                    ForEach(expensesVM.expenses.filter { exp in !defaultExpenses.contains(where: { $0.name == exp.category }) }) { expense in
                        OperationCategoryCircle(
                            icon: "cart.fill",
                            color: .red,
                            title: expense.category,
                            amount: "\(Int(abs(expense.amount))) ₸"
                        )
                        .onTapGesture { editItem = .expense(expense) }
                        .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                            providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                if let data = data as? Data, let idString = String(data: data, encoding: .utf8), let walletId = Int(idString), let wallet = walletsVM.wallets.first(where: { $0.id == walletId }) {
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
                    }
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
 
