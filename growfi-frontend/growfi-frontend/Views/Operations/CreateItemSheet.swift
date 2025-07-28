import SwiftUI
import Foundation // для PlanPeriod

struct CreateItemSheet: View {
    let type: OperationsView.CreateType
    var onCreate: (String, Double, String?, String?, String, Double, PlanPeriod?, Double?, PlanPeriod?, Int?, Int?, Date?) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var sum: String = ""
    @State private var selectedIcon: String = "creditcard.fill"
    @State private var selectedColor: Color = .blue
    @State private var selectedCurrency: String = "₸"
    @State private var initialAmount: String = ""
    @State private var planEnabled = false
    @State private var planPeriod: PlanPeriod = .month
    @State private var periodCount: Int = 6
    @State private var reminderPeriod: PlanPeriod? = .week // по умолчанию еженедельно
    @State private var selectedWeekday: Int = 2 // 2 = Monday (Swift: 1=Sunday, 2=Monday...)
    @State private var selectedMonthDay: Int = 1
    @State private var selectedTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showWeekdayPicker = false
    @State private var showMonthDayPicker = false
    @State private var showTimePicker = false
    @State private var forceUpdate = false
    @FocusState private var isNameFieldFocused: Bool
    let availableIcons = [
        "creditcard.fill", "banknote", "dollarsign.circle.fill", "wallet.pass.fill", "cart.fill", "gift.fill", "airplane", "car.fill", "cross.case.fill", "tshirt.fill", "scissors", "gamecontroller.fill", "cup.and.saucer.fill", "fork.knife", "phone.fill", "house.fill", "building.2.fill", "bag.fill", "star.fill", "questionmark.circle", "lipstick", "paintbrush.fill"
    ]
    let availableColors: [Color] = [.blue, .green, .yellow, .orange, .red, .purple, .mint, .gray]
    let availableCurrencies = ["₸", "$", "€", "₽"]
    
    init(type: OperationsView.CreateType, onCreate: @escaping (String, Double, String?, String?, String, Double, PlanPeriod?, Double?, PlanPeriod?, Int?, Int?, Date?) -> Void) {
        self.type = type
        self.onCreate = onCreate
        
        // Инициализируем @State переменные в зависимости от типа
        let (icon, color) = Self.getDefaultIconAndColor(for: type)
        _selectedIcon = State(initialValue: icon)
        _selectedColor = State(initialValue: color)
    }
    
    private static func getDefaultIconAndColor(for type: OperationsView.CreateType) -> (String, Color) {
        switch type {
        case .income:
            return ("dollarsign.circle.fill", .green)
        case .wallet:
            return ("creditcard.fill", .blue)
        case .goal:
            return ("leaf.circle.fill", .green)
        case .expense:
            return ("wallet.pass.fill", .red)
        }
    }
    
    // === ВНЕ структуры CreateItemSheet ===
    // (или внутри, но до body)

    // === ДОБАВЬ: вычисляемые свойства ===
    private var calculatedPayment: Int {
        guard let sumValue = Double(sum), let initialValue = Double(initialAmount), periodCount > 0 else { return 0 }
        let left = max(sumValue - initialValue, 0)
        return Int(left / Double(periodCount))
    }
    private var calculatedEndDate: Date {
        let calendar = Calendar.current
        let now = Date()
        switch planPeriod {
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: periodCount, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: periodCount, to: now) ?? now
        }
    }
    private var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: calculatedEndDate)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text(type == .wallet ? "create_wallet_title".localized : "create_title".localized)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.top, 16)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.blue)
                            .padding(.top, 16)
                    }
                }
                .id(forceUpdate) // Принудительное обновление
                Spacer().frame(height: 8)
                VStack(spacing: 8) {
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
                }
                .padding(.bottom, 8)
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("name".localized)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        TextField("enter_name".localized, text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .id("nameField")
                            .focused($isNameFieldFocused)
                            .keyboardToolbar {
                                hideKeyboard()
                            }
                    }
                    if type == .goal {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("goal_amount".localized)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            TextField("0", text: $sum)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("Уже накоплено")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            TextField("0", text: $initialAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            // Новый блок: планирование накоплений
                            Text("plan_title".localized)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.top, 8)
                            Picker("plan_periodicity".localized, selection: $planPeriod) {
                                Text("plan_week".localized).tag(PlanPeriod.week)
                                Text("plan_month".localized).tag(PlanPeriod.month)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            HStack {
                                Text("plan_count".localized)
                                Stepper(value: $periodCount, in: 1...120) {
                                    Text(String.localizedStringWithFormat("plan_count_format".localized, periodCount, planPeriod == .week ? "plan_week_plural".localized : "plan_month_plural".localized))
                                }
                            }
                            // Показываем только если введены суммы
                            if let sumValue = Double(sum), let initialValue = Double(initialAmount), periodCount > 0, sumValue > initialValue {
                                Text("Сумма взноса: \(calculatedPayment) за \(planPeriod == .week ? "неделю" : "месяц")")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Text("До цели: \(formattedEndDate)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            // Новый блок: выбор напоминания
                            Text("reminder_title".localized)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.top, 8)
                            Picker("reminder_periodicity".localized, selection: $reminderPeriod) {
                                Text("reminder_none".localized).tag(Optional<PlanPeriod>.none)
                                Text("reminder_weekly".localized).tag(Optional(PlanPeriod.week))
                                Text("reminder_monthly".localized).tag(Optional(PlanPeriod.month))
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            // --- Динамический UI для выбора дня/времени ---
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
                            }
                            if reminderPeriod == .month {
                                HStack(spacing: 12) {
                                    Button(action: { showMonthDayPicker = true }) {
                                        Text("reminder_month_day".localized + ": \(selectedMonthDay)")
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
                    } else if type == .wallet {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("wallet_amount_optional".localized)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            TextField("0", text: $sum)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    if type == .goal || type == .wallet {
                        HStack {
                            Text("currency".localized)
                                .font(.system(size: 16))
                            Spacer()
                            Picker("Валюта", selection: $selectedCurrency) {
                                ForEach(availableCurrencies, id: \.self) { currency in
                                    Text(currency)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Кнопка сохранения всегда видна
                Button(action: {
                    let amount: Double = (type == .goal || type == .wallet) ? (Double(sum) ?? 0) : 0
                    let finalName = name.isEmpty ? defaultName.localizedIfDefault : name
                    if type == .goal {
                        let initial = Double(initialAmount) ?? 0
                        let planAmount = calculatedPayment
                        
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
                        
                        print("DEBUG: CreateItemSheet - selectedMonthDay before save: \(selectedMonthDay)")
                        print("DEBUG: CreateItemSheet - finalSelectedMonthDay: \(finalSelectedMonthDay ?? -1)")
                        print("DEBUG: CreateItemSheet - reminderPeriod: \(reminderPeriod?.rawValue ?? "nil")")
                        print("DEBUG: CreateItemSheet - selectedWeekday: \(selectedWeekday)")
                        print("DEBUG: CreateItemSheet - finalSelectedWeekday: \(finalSelectedWeekday ?? -1)")
                        print("DEBUG: CreateItemSheet - calling onCreate with finalSelectedMonthDay: \(finalSelectedMonthDay ?? -1)")
                        print("DEBUG: CreateItemSheet - calling onCreate with finalSelectedWeekday: \(finalSelectedWeekday ?? -1)")
                        onCreate(finalName, amount, selectedIcon, selectedColor.toHex, selectedCurrency, initial, planPeriod, Double(planAmount), reminderPeriod, finalSelectedWeekday, finalSelectedMonthDay, finalSelectedTime)
                    } else {
                        onCreate(finalName, amount, selectedIcon, selectedColor.toHex, selectedCurrency, 0, nil, nil, nil, nil, nil, nil)
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("save".localized)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 16)
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
            DispatchQueue.main.async {
                if name.isEmpty {
                    name = ""
                }
                if sum.isEmpty {
                    sum = ""
                }
                if initialAmount.isEmpty {
                    initialAmount = ""
                }
                
                // Принудительно обновляем UI
                let _ = selectedIcon
                let _ = selectedColor
                let _ = selectedCurrency
                let _ = planEnabled
                let _ = planPeriod
                let _ = periodCount
                let _ = reminderPeriod
                let _ = selectedWeekday
                let _ = selectedMonthDay
                let _ = selectedTime
                
                // Принудительно обновляем UI
                forceUpdate.toggle()
                
                // Автоматически устанавливаем фокус на поле имени
                isNameFieldFocused = true
            }
        }
        // --- Pickers ---
        .sheet(isPresented: $showWeekdayPicker) {
            VStack {
                Text("reminder_choose_weekday".localized).font(.headline).padding()
                Picker("День недели", selection: $selectedWeekday) {
                    ForEach(1...7, id: \.self) { i in
                        Text(weekdayName(i)).tag(i)
                    }
                }
                .labelsHidden()
                .pickerStyle(WheelPickerStyle())
                Button("reminder_done".localized) { showWeekdayPicker = false }.padding()
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showMonthDayPicker) {
            VStack {
                Text("reminder_choose_month_day".localized).font(.headline).padding()
                Picker("Число месяца", selection: $selectedMonthDay) {
                    ForEach(1...31, id: \.self) { i in
                        Text("\(i)").tag(i)
                    }
                }
                .labelsHidden()
                .pickerStyle(WheelPickerStyle())
                Button("reminder_done".localized) { showMonthDayPicker = false }.padding()
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showTimePicker) {
            VStack {
                Text("reminder_choose_time".localized).font(.headline).padding()
                DatePicker("Время", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                Button("reminder_done".localized) { showTimePicker = false }.padding()
            }
            .presentationDetents([.medium])
        }
    }
    
    // Добавляю вычисляемое свойство для дефолтного имени
    private var defaultName: String {
        switch type {
        case .income: return "Income"
        case .wallet: return "Wallet"
        case .goal: return "Goal"
        case .expense: return "Expense"
        }
    }

    // --- helpers ---
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

extension Color {
    var toHex: String? {
        UIColor(self).toHexString
    }
}

extension UIColor {
    var toHexString: String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
    }
} 
