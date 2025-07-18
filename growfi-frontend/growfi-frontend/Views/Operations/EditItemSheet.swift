import SwiftUI

struct EditItemSheet: View {
    let item: OperationsView.EditableItem
    @ObservedObject var viewModel: GoalsViewModel
    var onClose: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var walletsVM: WalletsViewModel
    @EnvironmentObject var expensesVM: ExpensesViewModel
    @EnvironmentObject var incomesVM: IncomesViewModel
    @State private var name: String = ""
    @State private var sum: String = ""
    @State private var showDeleteAlert = false
    @State private var selectedIcon: String = "creditcard.fill"
    @State private var selectedColor: Color = .blue
    let availableIcons = [
        "creditcard.fill", "banknote", "dollarsign.circle.fill", "wallet.pass.fill", "cart.fill", "gift.fill", "airplane", "car.fill", "cross.case.fill", "tshirt.fill", "scissors", "gamecontroller.fill", "cup.and.saucer.fill", "fork.knife", "phone.fill", "house.fill", "building.2.fill", "bag.fill", "star.fill", "questionmark.circle", "lipstick", "paintbrush.fill"
    ]
    let availableColors: [Color] = [.blue, .green, .yellow, .orange, .red, .purple, .mint, .gray]

    init(item: OperationsView.EditableItem, viewModel: GoalsViewModel, onClose: @escaping () -> Void) {
        self.item = item
        self.viewModel = viewModel
        self.onClose = onClose
        
        // Инициализируем @State переменные в зависимости от типа элемента
        let (name, sum, icon, color) = Self.getInitialValues(for: item)
        _name = State(initialValue: name)
        _sum = State(initialValue: sum)
        _selectedIcon = State(initialValue: icon)
        _selectedColor = State(initialValue: color)
    }
    
    private static func getInitialValues(for item: OperationsView.EditableItem) -> (String, String, String, Color) {
        switch item {
        case .wallet(let w):
            return (w.name.localizedIfDefault, String(Int(w.balance)), "creditcard.fill", .blue)
        case .income(let i):
            return (i.name.localizedIfDefault, "", "dollarsign.circle.fill", .green)
        case .goal(let g):
            return (g.name.localizedIfDefault, String(Int(g.current_amount)), "leaf.circle.fill", .green)
        case .expense(let e):
            return (e.name.localizedIfDefault, "", "cart.fill", .red)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.blue)
                        .font(.system(size: 28))
                }
                Spacer()
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                Spacer()
                Button(action: { onClose(); presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 28))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            VStack(spacing: 16) {
                Text("icon".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                IconColorPickerView(
                    selectedIcon: $selectedIcon,
                    selectedColor: $selectedColor,
                    name: name,
                    availableIcons: availableIcons,
                    availableColors: availableColors
                )
                .padding(.bottom, 8)
                VStack(alignment: .leading, spacing: 4) {
                    Text("name".localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                if case .wallet = item {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amount".localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        TextField("0", text: $sum)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                } else if case .goal = item {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amount".localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        TextField("0", text: $sum)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                HStack {
                    Text("Currency".localized)
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text("₸")
                        .font(.system(size: 22, weight: .bold))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            Spacer()
            Button(action: {
                saveChanges()
                onClose()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Save".localized)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .disabled(name.isEmpty)
        }
        .background(Color.white)
        .cornerRadius(24)
        .ignoresSafeArea(edges: .bottom)
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete".localized),
                message: Text("IrreversibleAction".localized),
                primaryButton: .destructive(Text("Delete".localized), action: {
                    deleteItem()
                    onClose()
                    presentationMode.wrappedValue.dismiss()
                }),
                secondaryButton: .cancel(Text("Cancel".localized))
            )
        }
    }

    private var title: String {
        switch item {
        case .wallet: return "Wallet".localized
        case .income: return "Income".localized
        case .goal: return "Goal".localized
        case .expense: return "Expense".localized
        }
    }
    
    private func saveChanges() {
        let amount = Double(sum) ?? 0
        switch item {
        case .wallet(let w): viewModel.updateWallet(id: w.id, name: name, amount: amount, wallets: &walletsVM.wallets)
        case .income(let i): viewModel.updateIncome(id: i.id, name: name, amount: 0) // не трогаем сумму
        case .goal(let g): viewModel.updateGoal(id: g.id, name: name, amount: amount)
        case .expense(let e): expensesVM.updateExpense(id: e.id, name: name, icon: selectedIcon, color: selectedColor.toHex ?? "#000000", description: "")
        }
    }
    private func deleteItem() {
        switch item {
        case .wallet(let w):
            walletsVM.deleteWallet(id: w.id)
        case .income(let i):
            incomesVM.deleteIncome(id: i.id)
        case .goal(let g):
            viewModel.deleteGoal(goalId: g.id)
        case .expense(let e):
            expensesVM.deleteExpense(id: e.id)
        }
    }
} 
