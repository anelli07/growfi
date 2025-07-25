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
        case .incomeToWallet(_, _): return "Income".localized
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
        switch type {
        case .walletToGoal(let wallet, _):
            return amount > wallet.balance
        case .walletToExpense(let wallet, _):
            return amount > wallet.balance
        case .incomeToWallet:
            return false
        }
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
                    TextField("0", value: $amount, formatter: NumberFormatter())
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .keyboardToolbar(title: "Готово") {
                            hideKeyboard()
                        }
                    Text("₸")
                        .font(.system(size: 32, weight: .bold))
                }
                .padding(.bottom, 8)
                
                // Показываем предупреждение о недостаточности средств
                if case .walletToGoal(_, _) = type, isInsufficientFunds {
                    Text("insufficient_funds".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                } else if case .walletToExpense(_, _) = type, isInsufficientFunds {
                    Text("insufficient_funds".localized)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
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
                        .keyboardToolbar(title: "Готово") {
                            hideKeyboard()
                        }
                }
                .padding(.vertical, 8)
                
                // Кнопка сохранения всегда видна
                Button(action: {
                    // Проверяем достаточность средств для кошелька
                    if case .walletToGoal(let wallet, _) = type, amount > wallet.balance {
                        // Показываем ошибку - недостаточно средств
                        return
                    }
                    if case .walletToExpense(let wallet, _) = type, amount > wallet.balance {
                        // Показываем ошибку - недостаточно средств
                        return
                    }
                    onConfirm(amount, date, comment)
                }) {
                    Text("Сохранить".localized)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .disabled(amount <= 0 || isInsufficientFunds)
                
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
                    let _ = amount
                    let _ = date
                    let _ = comment
                    let _ = showDatePicker
                    
                    // Принудительно обновляем UI
                    forceUpdate.toggle()
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
