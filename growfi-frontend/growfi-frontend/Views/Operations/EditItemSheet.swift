import SwiftUI

struct EditItemSheet: View {
    let item: OperationsView.EditableItem
    @ObservedObject var viewModel: GoalsViewModel
    var onClose: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var sum: String = ""
    @State private var showDeleteAlert = false

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
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 80, height: 80)
                    iconView
                }
                .padding(.bottom, 8)
                VStack(alignment: .leading, spacing: 4) {
                    Text("название")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    TextField("", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Сумма")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    TextField("0", text: $sum)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
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
        .onAppear { fillFields() }
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
    private var iconView: some View {
        switch item {
        case .wallet: Image(systemName: "creditcard.fill").foregroundColor(.white).font(.system(size: 40))
        case .income: Image(systemName: "dollarsign.circle.fill").foregroundColor(.white).font(.system(size: 40))
        case .goal: Image(systemName: "leaf.circle.fill").foregroundColor(.white).font(.system(size: 40))
        case .expense: Image(systemName: "cart.fill").foregroundColor(.white).font(.system(size: 40))
        }
    }
    private var iconColor: Color {
        switch item {
        case .wallet: return .blue
        case .income: return .green
        case .goal: return .green
        case .expense: return .red
        }
    }
    private func fillFields() {
        switch item {
        case .wallet(let w): name = w.name; sum = String(Int(w.balance))
        case .income(let i): name = i.category; sum = String(Int(i.amount))
        case .goal(let g): name = g.name; sum = String(Int(g.current_amount))
        case .expense(let e): name = e.category; sum = String(Int(abs(e.amount)))
        }
    }
    private func saveChanges() {
        let amount = Double(sum) ?? 0
        switch item {
        case .wallet(let w): viewModel.updateWallet(id: w.id, name: name, amount: amount)
        case .income(let i): viewModel.updateIncome(id: i.id, name: name, amount: amount)
        case .goal(let g): viewModel.updateGoal(id: g.id, name: name, amount: amount)
        case .expense(let e): viewModel.updateExpense(id: e.id, name: name, amount: amount)
        }
    }
    private func deleteItem() {
        switch item {
        case .wallet(let w): viewModel.deleteWallet(id: w.id)
        case .income(let i): viewModel.deleteIncome(id: i.id)
        case .goal(let g): viewModel.deleteGoal(id: g.id)
        case .expense(let e): viewModel.deleteExpense(id: e.id)
        }
    }
} 