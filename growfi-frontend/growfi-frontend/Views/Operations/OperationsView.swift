import SwiftUI

enum TransferType {
    case incomeToWallet(Transaction, Wallet)
    case walletToGoal(Wallet, Goal)
    case walletToExpense(Wallet, Transaction)
}

struct OperationsView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
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

    enum CreateType { case income, wallet, goal, expense }

    var incomeTotal: Double { viewModel.incomes.map { $0.amount }.reduce(0, +) }
    var walletTotal: Double { viewModel.wallets.map { $0.balance }.reduce(0, +) }
    var expenseTotal: Double { viewModel.expenses.map { abs($0.amount) }.reduce(0, +) }

    let defaultExpenses: [(name: String, icon: String, color: Color)] = [
        ("Развлечения", "gamecontroller.fill", .purple),
        ("Связь", "phone.fill", .teal),
        ("Транспорт", "car.fill", .orange),
        ("Еда", "fork.knife", .red)
    ]

    @State private var showIncome = true
    @State private var showWallets = true
    @State private var showGoals = true
    @State private var showExpenses = true

    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                
                // Доходы
                SectionToggleHeader(title: "Доходы", total: "\(Int(incomeTotal)) ₸", isExpanded: .constant(true))
                CategoryGrid(content: {
                    ForEach(viewModel.incomes) { income in
                        OperationCategoryCircle(icon: "dollarsign.circle.fill", color: .green, title: income.category, amount: "\(Int(income.amount)) ₸")
                            .onDrag {
                                dragIncomeId = income.id
                                dragAmount = income.amount
                                return NSItemProvider(object: income.id.uuidString as NSString)
                            } preview: {
                                ZStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 48, height: 48)
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
                }, isScrollable: true, verticalPadding: 8)

                // Кошельки
                SectionHeader(title: "Кошельки", total: "\(Int(walletTotal)) ₸")
                CategoryGrid(content: {
                    ForEach(viewModel.wallets) { wallet in
                        OperationCategoryCircle(icon: "creditcard.fill", color: .blue, title: wallet.name, amount: "\(Int(wallet.balance)) ₸")
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
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 48, height: 48)
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
                }, isScrollable: true, verticalPadding: 8)

                // Цели
                SectionHeader(title: "Цели", total: "")
                CategoryGrid(content: {
                    ForEach(viewModel.goals) { goal in
                        OperationCategoryCircle(
                            icon: "leaf.circle.fill",
                            color: .green,
                            title: goal.name,
                            amount: "\(Int(goal.current_amount))/\(Int(goal.target_amount)) ₸"
                        )
                        .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                            providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                if let data = data as? Data, let idString = String(data: data, encoding: .utf8), let walletId = Int(idString), let wallet = viewModel.wallets.first(where: { $0.id == walletId }) {
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
                }, isScrollable: true, verticalPadding: 8)

                // Расходы
                SectionHeader(title: "Расходы", total: "\(Int(expenseTotal)) ₸")
                CategoryGrid(content: {
                    ForEach(defaultExpenses, id: \.name) { def in
                        let expense = viewModel.expenses.first(where: { $0.category == def.name })
                        let amount = expense.map { abs($0.amount) } ?? 0
                        OperationCategoryCircle(
                            icon: def.icon,
                            color: def.color,
                            title: def.name,
                            amount: "\(Int(amount)) ₸"
                        )
                        .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                            providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                if let data = data as? Data, let idString = String(data: data, encoding: .utf8), let walletId = Int(idString), let wallet = viewModel.wallets.first(where: { $0.id == walletId }) {
                                    DispatchQueue.main.async {
                                        let exp = expense ?? viewModel.addExpenseAndReturn(name: def.name)
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
                    ForEach(viewModel.expenses.filter { exp in !defaultExpenses.contains(where: { $0.name == exp.category }) }) { expense in
                        OperationCategoryCircle(
                            icon: "cart.fill",
                            color: .red,
                            title: expense.category,
                            amount: "\(Int(abs(expense.amount))) ₸"
                        )
                        .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                            providers.first?.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
                                if let data = data as? Data, let idString = String(data: data, encoding: .utf8), let walletId = Int(idString), let wallet = viewModel.wallets.first(where: { $0.id == walletId }) {
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
                }, isScrollable: false, verticalPadding: 8)
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
                        viewModel.transferIncomeToWallet(incomeId: income.id, walletId: wallet.id, amount: amount)
                    case .walletToGoal(let wallet, let goal):
                        let ok = viewModel.transferWalletToGoal(walletId: wallet.id, goalId: goal.id, amount: amount)
                        if !ok {
                            alertMessage = "Недостаточно денег в кошельке"
                            showAlert = true
                        }
                    case .walletToExpense(let wallet, let expense):
                        let ok = viewModel.transferWalletToExpense(walletId: wallet.id, expenseId: expense.id, amount: amount)
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
                CreateItemSheet(type: type) { name, sum in
                    switch type {
                    case .income:
                        viewModel.addIncome(name: name, amount: sum)
                    case .wallet:
                        viewModel.addWallet(name: name, amount: sum)
                    case .goal:
                        viewModel.addGoal(name: name, amount: sum)
                    case .expense:
                        viewModel.addExpense(name: name, amount: sum)
                    }
                    showCreateSheet = false
                }
            }
        }
    }

    struct CategoryGrid<Content: View>: View {
        @ViewBuilder let content: () -> Content
        var isScrollable: Bool = false
        var verticalPadding: CGFloat = 0

        // ширина иконки + отступ = примерно 72 (56 иконка + 16 отступ)
        private let itemWidth: CGFloat = 72

        var body: some View {
            VStack {
                if isScrollable {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            content()
                        }
                        .padding(.horizontal, 8)
                        .frame(minHeight: 100) // чтобы не прыгал по высоте
                    }
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 16) {
                        content()
                    }
                }
            }
            .padding(.vertical, verticalPadding)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
    }
}
#endif
