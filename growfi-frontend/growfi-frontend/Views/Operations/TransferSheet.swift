import SwiftUI

enum TransferType: Identifiable {
    case incomeToWallet(Income, Wallet)
    case walletToGoal(Wallet, Goal)
    case walletToExpense(Wallet, Expense)
    
    var id: String {
        switch self {
        case .incomeToWallet(let income, let wallet): return "income_\(income.id)_wallet_\(wallet.id)"
        case .walletToGoal(let wallet, let goal): return "wallet_\(wallet.id)_goal_\(goal.id)"
        case .walletToExpense(let wallet, let expense): return "wallet_\(wallet.id)_expense_\(expense.id)"
        }
    }
}

struct TransferSheet: View {
    let type: TransferType
    @Binding var amount: Double
    @Binding var date: Date
    @Binding var comment: String
    var onConfirm: (Double, Date, String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showDatePicker: Bool = false
    @State private var forceUpdate = false
    @FocusState private var isAmountFieldFocused: Bool
    @State private var amountText: String = ""
    
    init(type: TransferType, amount: Binding<Double>, date: Binding<Date>, comment: Binding<String>, onConfirm: @escaping (Double, Date, String) -> Void) {
        self.type = type
        self._amount = amount
        self._date = date
        self._comment = comment
        self.onConfirm = onConfirm
    }
    
    // Универсальные вычисления для левой и правой части
    var leftTitle: String {
        switch type {
        case .incomeToWallet(let income, _): return income.name.localizedIfDefault
        case .walletToGoal(let wallet, _): return wallet.name.localizedIfDefault
        case .walletToExpense(let wallet, _): return wallet.name.localizedIfDefault
        }
    }
    var leftSubtitle: String {
        switch type {
        case .incomeToWallet(_, _): return "Income".localized
        case .walletToGoal: return "Wallet".localized
        case .walletToExpense: return "Wallet".localized
        }
    }
    var leftAmount: String {
        switch type {
        case .incomeToWallet(_ /* income */, _): return "0 ₸"
        case .walletToGoal(let wallet, _): return "\(Int(wallet.balance)) ₸"
        case .walletToExpense(let wallet, _): return "\(Int(wallet.balance)) ₸"
        }
    }
    var leftIcon: String {
        switch type {
        case .incomeToWallet: return "dollarsign.circle.fill"
        case .walletToGoal, .walletToExpense: return "creditcard.fill"
        }
    }
    var leftColor: Color {
        switch type {
        case .incomeToWallet: return .green
        case .walletToGoal, .walletToExpense: return .blue
        }
    }
    var rightTitle: String {
        switch type {
        case .incomeToWallet(_, let wallet): return wallet.name.localizedIfDefault
        case .walletToGoal(_, let goal): return goal.name.localizedIfDefault
        case .walletToExpense(_, let expense): return expense.name.localizedIfDefault
        }
    }
    var rightSubtitle: String {
        switch type {
        case .incomeToWallet(_, _): return "wallet".localized
        case .walletToGoal(_, _): return "goal".localized
        case .walletToExpense(_, _): return "expense".localized
        }
    }
    var rightAmount: String {
        switch type {
        case .incomeToWallet(_, let wallet): return "\(Int(wallet.balance)) ₸"
        case .walletToGoal(_, let goal): return "\(Int(goal.current_amount)) / \(Int(goal.target_amount)) ₸"
        case .walletToExpense(_, let expense): return "\(Int(expense.amount)) ₸"
        }
    }
    var rightIcon: String {
        switch type {
        case .incomeToWallet: return "creditcard.fill"
        case .walletToGoal: return "leaf.circle.fill"
        case .walletToExpense: return "cart.fill"
        }
    }
    var rightColor: Color {
        switch type {
        case .incomeToWallet: return .blue
        case .walletToGoal: return .green
        case .walletToExpense: return .red
        }
    }
    
    // Функция для расчета максимально доступной суммы для пополнения цели
    var maxAvailableAmount: Double {
        switch type {
        case .walletToGoal(let wallet, let goal):
            let walletLimit = wallet.balance
            let goalLimit = goal.target_amount - goal.current_amount
            return min(walletLimit, goalLimit)
        case .walletToExpense(let wallet, _):
            return wallet.balance
        case .incomeToWallet(_, _):
            return Double.infinity
        }
    }
    
    // Функция для расчета периодов накопления
    func calculateAccumulationPeriods() -> [AccumulationPeriod] {
        guard case .walletToGoal(_, let goal) = type else {
            print("DEBUG: Не walletToGoal тип")
            return []
        }
        
        print("DEBUG: Цель - \(goal.name)")
        print("DEBUG: planPeriod = \(goal.planPeriod?.rawValue ?? "nil")")
        print("DEBUG: planAmount = \(goal.planAmount ?? -1)")
        print("DEBUG: createdAt = \(goal.createdAt?.description ?? "nil")")
        
        // Проверяем, есть ли у цели план накопления
        guard let planPeriod = goal.planPeriod,
              let planAmount = goal.planAmount,
              let createdAt = goal.createdAt else {
            print("DEBUG: Нет плана накопления - возвращаем пустой массив")
            return []
        }
        
        let calendar = Calendar.current
        let totalAmount = goal.target_amount
        let totalPeriods = Int(ceil(totalAmount / planAmount))
        var periods: [AccumulationPeriod] = []
        
        // Рассчитываем все периоды до достижения цели
        for i in 0..<totalPeriods {
            let periodDate: Date
            if planPeriod == .week {
                periodDate = calendar.date(byAdding: .weekOfYear, value: i, to: createdAt) ?? createdAt
            } else {
                periodDate = calendar.date(byAdding: .month, value: i, to: createdAt) ?? createdAt
            }
            
            let periodAmount = min(planAmount, totalAmount - Double(i) * planAmount)
            
            // Рассчитываем прогресс для этого периода
            let periodStartAmount = Double(i) * planAmount
            let periodEndAmount = Double(i + 1) * planAmount
            let currentAmountInPeriod = min(goal.current_amount - periodStartAmount, planAmount)
            let progressAmount = max(0, currentAmountInPeriod)
            
            let isCompleted = goal.current_amount >= periodEndAmount
            
            periods.append(AccumulationPeriod(
                date: periodDate,
                targetAmount: periodAmount,
                progressAmount: progressAmount,
                isCompleted: isCompleted,
                periodNumber: i + 1
            ))
        }
        
        return periods
    }
    
    var title: String {
        switch type {
        case .incomeToWallet: return "TopUp".localized
        case .walletToGoal: return "Goal".localized
        case .walletToExpense: return "Expense".localized
        }
    }
    var dateOptions: [Date] {
        let calendar = Calendar.current
        // Показываем 7 дней назад, сегодня, 7 дней вперёд
        let days = (-7...7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: Date())
        }
        return days
    }
    func dateShort(_ d: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: d)
    }
    func dateWeekday(_ d: Date) -> String {
        let lang = AppLanguageManager.shared.currentLanguage.rawValue
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang)
        formatter.dateFormat = "EEEE"
        return formatter.string(from: d).capitalized
    }
    func dateSpecial(_ d: Date) -> String? {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "today".localized }
        if cal.isDateInYesterday(d) { return "yesterday".localized }
        return nil
    }
    
    var isInsufficientFunds: Bool {
        let currentAmount = Double(amountText) ?? 0
        switch type {
        case .walletToGoal(let wallet, _):
            return currentAmount > wallet.balance
        case .walletToExpense(let wallet, _):
            return currentAmount > wallet.balance
        case .incomeToWallet:
            return false
        }
    }
    
    var isGoalAmountExceeded: Bool {
        let currentAmount = Double(amountText) ?? 0
        switch type {
        case .walletToGoal(_, let goal):
            let remaining = goal.target_amount - goal.current_amount
            return currentAmount > remaining
        case .walletToExpense, .incomeToWallet:
            return false
        }
    }
    
    var isButtonDisabled: Bool {
        let currentAmount = Double(amountText) ?? 0
        return amountText.isEmpty || currentAmount <= 0 || isInsufficientFunds || isGoalAmountExceeded
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text(title)
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
                Text("amount".localized)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.gray)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("", text: $amountText)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($isAmountFieldFocused)
                        .keyboardToolbar {
                            hideKeyboard()
                        }
                        .onChange(of: amountText) { newValue in
                            // Обновляем amount только если введено валидное число
                            if let doubleValue = Double(newValue) {
                                amount = doubleValue
                            }
                        }
                    Text("₸")
                        .font(.system(size: 32, weight: .bold))
                }
                .padding(.bottom, 8)
                
                // Показываем предупреждения
                if case .walletToGoal(_, let goal) = type {
                    if isInsufficientFunds {
                        Text("insufficient_funds".localized)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.bottom, 8)
                    } else if isGoalAmountExceeded {
                        let remaining = goal.target_amount - goal.current_amount
                        Text(String(format: "max_amount_to_add".localized, "\(Int(remaining))"))
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.bottom, 8)
                    }
                } else if case .walletToExpense(_, _) = type, isInsufficientFunds {
                    Text("insufficient_funds".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                }
                
                // Показываем максимально доступную сумму для целей
                if case .walletToGoal(_, let goal) = type {
                    let remaining = goal.target_amount - goal.current_amount
                    if remaining > 0 {
                        Text(String(format: "max_available_amount".localized, "\(Int(remaining))"))
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.bottom, 8)
                    } else {
                        Text("goal_already_completed".localized)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.bottom, 8)
                    }
                }
                // Универсальный блок: слева и справа
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text(leftSubtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(leftTitle)
                            .font(.system(size: 16, weight: .semibold))
                        ZStack {
                            Circle()
                                .fill(leftColor)
                                .frame(width: 56, height: 56)
                            Image(systemName: leftIcon)
                                .foregroundColor(.white)
                                .font(.system(size: 28))
                        }
                        if !leftAmount.isEmpty {
                            Text(leftAmount)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    VStack(spacing: 4) {
                        Text(rightSubtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(rightTitle)
                            .font(.system(size: 16, weight: .semibold))
                        ZStack {
                            Circle()
                                .fill(rightColor)
                                .frame(width: 56, height: 56)
                            Image(systemName: rightIcon)
                                .foregroundColor(.white)
                                .font(.system(size: 28))
                        }
                        if !rightAmount.isEmpty {
                            Text(rightAmount)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 16)
                
                // Компонент прогресса накопления для целей
                if case .walletToGoal(_, let goal) = type {
                    let periods = calculateAccumulationPeriods()
                    
                    AccumulationProgressView(
                        periods: periods,
                        planPeriod: goal.planPeriod ?? .week
                    )
                    .padding(.vertical, 8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Дата".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    HStack(spacing: 8) {
                        Button(action: { showDatePicker = true }) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                        }
                        ScrollViewReader { scrollProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(dateOptions, id: \.self) { d in
                                        VStack(spacing: 2) {
                                            Text(dateShort(d))
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(Calendar.current.isDate(d, inSameDayAs: date) ? .black : .gray)
                                            Text(dateWeekday(d))
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                            if let special = dateSpecial(d) {
                                                Text(special)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Calendar.current.isDate(d, inSameDayAs: date) ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture { date = d }
                                        .id(d)
                                    }
                                }
                            }
                            .onAppear {
                                // Скроллим к сегодняшней дате (по центру/справа)
                                if let today = dateOptions.first(where: { Calendar.current.isDateInToday($0) }) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        scrollProxy.scrollTo(today, anchor: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .sheet(isPresented: $showDatePicker) {
                    VStack {
                        HStack {
                            Text("Выберите дату".localized)
                                .font(.headline)
                            Spacer()
                            Button(action: { showDatePicker = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .padding()
                            .environment(\.locale, Locale(identifier: AppLanguageManager.shared.currentLanguage.rawValue))
                        Spacer()
                        Button(action: { showDatePicker = false }) {
                            Text("Сохранить".localized)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .presentationDetents([.medium, .large])
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Комментарий".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    TextField("Комментарий".localized, text: $comment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                .padding(.vertical, 8)
                
                // Кнопка сохранения
                Button(action: {
                    let finalAmount = Double(amountText) ?? 0
                    onConfirm(finalAmount, date, comment)
                }) {
                    Text("Сохранить".localized)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isButtonDisabled ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .disabled(isButtonDisabled)
                
                // Дополнительный отступ для клавиатуры
                Spacer(minLength: 100)
            }
            .background(Color.white)
            .cornerRadius(24)
            .ignoresSafeArea(edges: .bottom)
            .hideKeyboardOnTap()
            .onAppear {
                // Принудительно инициализируем состояние при появлении
                DispatchQueue.main.async {
                    // Очищаем текстовое поле суммы
                    amountText = ""
                    amount = 0
                    let _ = date
                    let _ = comment
                    let _ = showDatePicker
                    
                    // Принудительно обновляем UI
                    forceUpdate.toggle()
                    
                    // Автоматически устанавливаем фокус на поле суммы
                    isAmountFieldFocused = true
                }
            }
            .sheet(isPresented: $showDatePicker) {
                VStack {
                    HStack {
                        Text("Выберите дату".localized)
                            .font(.headline)
                        Spacer()
                        Button(action: { showDatePicker = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding()
                        .environment(\.locale, Locale(identifier: AppLanguageManager.shared.currentLanguage.rawValue))
                    Spacer()
                    Button(action: { showDatePicker = false }) {
                        Text("Сохранить".localized)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .presentationDetents([.medium, .large])
            }
            .hideKeyboardOnTap()
        }
    }
}

// MARK: - Date Extension
extension Date {
    func toBackendString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

// MARK: - Accumulation Period Models
struct AccumulationPeriod: Identifiable {
    let id = UUID()
    let date: Date
    let targetAmount: Double
    let progressAmount: Double
    let isCompleted: Bool
    let periodNumber: Int
}

// MARK: - Accumulation Progress View
struct AccumulationProgressView: View {
    let periods: [AccumulationPeriod]
    let planPeriod: PlanPeriod?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("plan_progress".localized)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            if periods.isEmpty {
                Text("Нет данных для отображения")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
            } else {
                // Горизонтальный скролл с пагинацией по 12 кругов
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(periods) { period in
                            VStack(spacing: 6) {
                                ZStack {
                                    // Фон круга
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                        .frame(width: 50, height: 50)
                                    
                                    // Прогресс заполнения
                                    if period.progressAmount > 0 {
                                        Circle()
                                            .trim(from: 0, to: min(period.progressAmount / period.targetAmount, 1.0))
                                            .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                            .frame(width: 50, height: 50)
                                            .rotationEffect(.degrees(-90))
                                    }
                                    
                                    // Текст с прогрессом
                                    VStack(spacing: 2) {
                                        Text("\(Int(period.progressAmount))")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.green)
                                        Text("/")
                                            .font(.system(size: 8))
                                            .foregroundColor(.gray)
                                        Text("\(Int(period.targetAmount))")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                // Дата периода
                                Text(formatPeriodDate(period.date, planPeriod: planPeriod))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(width: 60)
                            }
                            .frame(width: 60)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    private func formatPeriodDate(_ date: Date, planPeriod: PlanPeriod?) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        
        if planPeriod == .week {
            formatter.dateFormat = "dd MMM"
        } else {
            formatter.dateFormat = "MMM yyyy"
        }
        
        return formatter.string(from: date).uppercased()
    }
}
