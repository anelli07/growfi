import SwiftUI
import Foundation // для PlanPeriod

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
    @State private var reminderPeriod: PlanPeriod? = nil
    @State private var selectedWeekday: Int = 2 // 2 = Monday
    @State private var selectedMonthDay: Int = 1
    @State private var selectedTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showWeekdayPicker = false
    @State private var showMonthDayPicker = false
    @State private var showTimePicker = false
    @State private var targetAmount: String = ""
    @State private var currentAmount: String = ""
    @FocusState private var isNameFieldFocused: Bool
    let availableIcons = [
        "creditcard.fill", "banknote", "dollarsign.circle.fill", "wallet.pass.fill", "cart.fill", "gift.fill", "airplane", "car.fill", "cross.case.fill", "tshirt.fill", "scissors", "gamecontroller.fill", "cup.and.saucer.fill", "fork.knife", "phone.fill", "house.fill", "building.2.fill", "bag.fill", "star.fill", "questionmark.circle", "lipstick", "paintbrush.fill"
    ]
    let availableColors: [Color] = [.blue, .green, .yellow, .orange, .red, .purple, .mint, .gray]

    init(item: OperationsView.EditableItem, viewModel: GoalsViewModel, onClose: @escaping () -> Void) {
        self.item = item
        self.viewModel = viewModel
        self.onClose = onClose
        
        // Инициализируем @State переменные в зависимости от типа элемента
        switch item {
        case .goal(let g):
            _name = State(initialValue: g.name.localizedIfDefault)
            _targetAmount = State(initialValue: String(Int(g.target_amount)))
            _currentAmount = State(initialValue: String(Int(g.current_amount)))
            _selectedIcon = State(initialValue: g.icon)
            _selectedColor = State(initialValue: Color(hex: g.color))
            _reminderPeriod = State(initialValue: PlanPeriod(rawValue: g.reminderPeriod ?? ""))
            _selectedWeekday = State(initialValue: g.selectedWeekday ?? 2)
            _selectedMonthDay = State(initialValue: g.selectedMonthDay ?? 1)
            if let timeString = g.selectedTime {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                let date = formatter.date(from: timeString) ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
                _selectedTime = State(initialValue: date)
            } else {
                _selectedTime = State(initialValue: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!)
            }
        case .wallet(let w):
            _name = State(initialValue: w.name.localizedIfDefault)
            _targetAmount = State(initialValue: String(Int(w.balance)))
            _currentAmount = State(initialValue: "")
            _selectedIcon = State(initialValue: "creditcard.fill")
            _selectedColor = State(initialValue: .blue)
        case .income(let i):
            _name = State(initialValue: i.name.localizedIfDefault)
            _targetAmount = State(initialValue: "")
            _currentAmount = State(initialValue: "")
            _selectedIcon = State(initialValue: "dollarsign.circle.fill")
            _selectedColor = State(initialValue: .green)
        case .expense(let e):
            _name = State(initialValue: e.name.localizedIfDefault)
            _targetAmount = State(initialValue: "")
            _currentAmount = State(initialValue: "")
            _selectedIcon = State(initialValue: "cart.fill")
            _selectedColor = State(initialValue: .red)
        }
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
    
    // MARK: - View Components
    private var headerView: some View {
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
    }
    
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 4) {
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
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("name".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            TextField("", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .id("nameField")
                .focused($isNameFieldFocused)
                .keyboardToolbar {
                    hideKeyboard()
                }
        }
    }
    
    @ViewBuilder
    private var goalSpecificSection: some View {
        if case .goal = item {
            VStack(alignment: .leading, spacing: 4) {
                Text("Amount".localized) // Target amount
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                TextField("0", text: $targetAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("already_saved_amount".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                TextField("already_saved_amount_placeholder".localized, text: $currentAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onLanguageChange()
                // Новый блок: выбор напоминания
                Text("Напоминать о взносе")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.top, 8)
                Picker("Периодичность напоминания", selection: $reminderPeriod) {
                    Text("Не напоминать").tag(Optional<PlanPeriod>.none)
                    Text("Еженедельно").tag(Optional(PlanPeriod.week))
                    Text("Ежемесячно").tag(Optional(PlanPeriod.month))
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: reminderPeriod) {
                    if reminderPeriod == nil {
                        selectedWeekday = 2
                        selectedMonthDay = 1
                        selectedTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
                    }
                }
                if reminderPeriod == .week {
                    HStack(spacing: 12) {
                        Button(action: { showWeekdayPicker = true }) {
                            Text("reminder_day".localized + ": " + weekdayName(selectedWeekday))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        Button(action: { showTimePicker = true }) {
                            Text("reminder_time".localized + ": " + timeString(selectedTime))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .onLanguageChange()
                } else if reminderPeriod == .month {
                    HStack(spacing: 12) {
                        Button(action: { showMonthDayPicker = true }) {
                            Text("reminder_month_day".localized + ": " + String(selectedMonthDay))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        Button(action: { showTimePicker = true }) {
                            Text("reminder_time".localized + ": " + timeString(selectedTime))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .onLanguageChange()
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
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                VStack(spacing: 16) {
                                         iconSection
                     nameSection
                     goalSpecificSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Кнопка сохранения всегда видна
                Button(action: {
                    if case .goal(let g) = item {
                        let tAmount = Double(targetAmount) ?? g.target_amount
                        let cAmount = Double(currentAmount) ?? g.current_amount
                        // Создаём обновлённую цель
                        var updatedGoal = g
                        updatedGoal.name = name
                        updatedGoal.target_amount = tAmount
                        updatedGoal.current_amount = cAmount
                        updatedGoal.icon = selectedIcon
                        updatedGoal.color = selectedColor.toHex ?? g.color
                        // Устанавливаем дефолтные значения для напоминаний
                        var finalSelectedWeekday: Int? = selectedWeekday
                        var finalSelectedMonthDay: Int? = selectedMonthDay
                        var finalSelectedTime: Date? = selectedTime
                        
                        if let reminderPeriod = reminderPeriod {
                            // Если не выбрано время, устанавливаем 9:00
                            if finalSelectedTime == nil {
                                let calendar = Calendar.current
                                var components = DateComponents()
                                components.hour = 9
                                components.minute = 0
                                finalSelectedTime = calendar.date(from: components) ?? Date()
                            }
                            
                            if reminderPeriod == .week {
                                // Для еженедельных напоминаний НЕ устанавливаем день месяца
                                finalSelectedMonthDay = nil
                                // Если не выбран день недели, устанавливаем понедельник (1)
                                if finalSelectedWeekday == nil {
                                    finalSelectedWeekday = 1
                                }
                            } else if reminderPeriod == .month {
                                // Для ежемесячных напоминаний НЕ устанавливаем день недели
                                finalSelectedWeekday = nil
                                // Если не выбрано число месяца, устанавливаем 1
                                if finalSelectedMonthDay == nil {
                                    finalSelectedMonthDay = 1
                                }
                            }
                        }
                        
                        viewModel.updateGoal(goal: updatedGoal, icon: updatedGoal.icon, color: updatedGoal.color, planPeriod: reminderPeriod, planAmount: nil, reminderPeriod: reminderPeriod, selectedWeekday: finalSelectedWeekday, selectedMonthDay: finalSelectedMonthDay, selectedTime: finalSelectedTime ?? Date())
                    } else {
                        saveChanges()
                    }
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
                .padding(.top, 20)
                .padding(.bottom, 24)
                .disabled(name.isEmpty)
                
                // Дополнительное пространство для прокрутки
                VStack(spacing: 20) {
                    Text("")
                        .frame(height: 50)
                    Text("")
                        .frame(height: 50)
                    Text("")
                        .frame(height: 50)
                }
                
                // Дополнительный отступ для клавиатуры
                Spacer(minLength: 300)
            }
        }

        .background(Color.white)
        .cornerRadius(24)
        .ignoresSafeArea(edges: .bottom)
        .hideKeyboardOnTap()
        .onAppear {
            // Принудительно инициализируем состояние при появлении
            if name.isEmpty {
                name = ""
            }
            if sum.isEmpty {
                sum = ""
            }
            if targetAmount.isEmpty {
                targetAmount = ""
            }
            if currentAmount.isEmpty {
                currentAmount = ""
            }
            
            // Автоматически устанавливаем фокус на поле имени
            DispatchQueue.main.async {
                isNameFieldFocused = true
            }
        }
        .sheet(isPresented: $showWeekdayPicker) {
            VStack {
                Text("Выберите день недели").font(.headline).padding()
                Picker("День недели", selection: $selectedWeekday) {
                    ForEach(1...7, id: \.self) { i in
                        Text(weekdayName(i)).tag(i)
                    }
                }
                .labelsHidden()
                .pickerStyle(WheelPickerStyle())
                Button("Готово") { showWeekdayPicker = false }.padding()
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showMonthDayPicker) {
            VStack {
                Text("Выберите число месяца").font(.headline).padding()
                Picker("Число месяца", selection: $selectedMonthDay) {
                    ForEach(1...31, id: \.self) { i in
                        Text("\(i)").tag(i)
                    }
                }
                .labelsHidden()
                .pickerStyle(WheelPickerStyle())
                Button("Готово") { showMonthDayPicker = false }.padding()
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showTimePicker) {
            VStack {
                Text("Выберите время").font(.headline).padding()
                DatePicker("Время", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                Button("Готово") { showTimePicker = false }.padding()
            }
            .presentationDetents([.medium])
        }
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
        let tAmount = Double(targetAmount) ?? 0
        switch item {
        case .wallet(let w):
            walletsVM.updateWallet(id: w.id, name: name, balance: amount, icon: selectedIcon, color: selectedColor.toHex ?? "#000000")
        case .income(let i):
            viewModel.updateIncome(id: i.id, name: name, amount: 0) // не трогаем сумму
        case .goal(let g):
            viewModel.updateGoal(id: g.id, name: name, amount: amount, targetAmount: tAmount)
        case .expense(let e):
            expensesVM.updateExpense(id: e.id, name: name, icon: selectedIcon, color: selectedColor.toHex ?? "#000000", description: "")
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
    
    // Helper функции для форматирования
    private func weekdayName(_ i: Int) -> String {
        let calendar = Calendar.current
        let locale = Locale(identifier: AppLanguageManager.shared.currentLanguage.rawValue)
        var components = DateComponents()
        components.weekday = i
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE"
        let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTimePreservingSmallerComponents) ?? Date()
        return formatter.string(from: date).capitalized
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppLanguageManager.shared.currentLanguage.rawValue)
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
