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
                Text("Иконка")
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
                    Text("название")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                if case .wallet = item {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Сумма")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        TextField("0", text: $sum)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                } else if case .goal = item {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Сумма")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        TextField("0", text: $sum)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                HStack {
                    Text("Валюта")
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
                Text("Сохранить")
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
        .onAppear { fillFields(); initIconColor() }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Удалить?"),
                message: Text("Действие необратимо"),
                primaryButton: .destructive(Text("Удалить"), action: {
                    deleteItem()
                    onClose()
                    presentationMode.wrappedValue.dismiss()
                }),
                secondaryButton: .cancel()
            )
        }
    }

    private var title: String {
        switch item {
        case .wallet: return "Кошелек"
        case .income: return "Доход"
        case .goal: return "Цель"
        case .expense: return "Расход"
        }
    }
    private func initIconColor() {
        switch item {
        case .wallet: selectedIcon = "creditcard.fill"; selectedColor = .blue
        case .income: selectedIcon = "dollarsign.circle.fill"; selectedColor = .green
        case .goal: selectedIcon = "leaf.circle.fill"; selectedColor = .green
        case .expense: selectedIcon = "cart.fill"; selectedColor = .red
        }
    }
    private func fillFields() {
        switch item {
        case .wallet(let w):
            name = w.name
            sum = String(Int(w.balance))
        case .income(let i):
            name = i.name
            sum = ""
        case .goal(let g):
            name = g.name
            sum = String(Int(g.current_amount))
        case .expense(let e):
            name = e.name
            sum = ""
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
