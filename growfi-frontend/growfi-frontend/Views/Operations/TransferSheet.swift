import SwiftUI

struct TransferSheet: View {
    let type: TransferType
    @Binding var amount: Double
    @Binding var date: Date
    @Binding var comment: String
    var onConfirm: (Double, Date, String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showDatePicker: Bool = false
    
    // Универсальные вычисления для левой и правой части
    var leftTitle: String {
        switch type {
        case .incomeToWallet(let income, _): return income.category
        case .walletToGoal(let wallet, _): return wallet.name
        case .walletToExpense(let wallet, _): return wallet.name
        }
    }
    var leftSubtitle: String {
        switch type {
        case .incomeToWallet(let income, _): return "Доход"
        case .walletToGoal: return "Кошелек"
        case .walletToExpense: return "Кошелек"
        }
    }
    var leftAmount: String {
        switch type {
        case .incomeToWallet(let income, _): return "\(Int(income.amount)) ₸"
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
        case .incomeToWallet(_, let wallet): return wallet.name
        case .walletToGoal(_, let goal): return goal.name
        case .walletToExpense(_, let expense): return expense.category
        }
    }
    var rightSubtitle: String {
        switch type {
        case .incomeToWallet: return "Кошелек"
        case .walletToGoal: return "Цель"
        case .walletToExpense: return "Категория"
        }
    }
    var rightAmount: String {
        switch type {
        case .incomeToWallet(_, let wallet): return "\(Int(wallet.balance)) ₸"
        case .walletToGoal(_, let goal): return "\(Int(goal.current_amount)) ₸"
        case .walletToExpense: return ""
        }
    }
    var rightIcon: String {
        switch type {
        case .incomeToWallet: return "creditcard.fill"
        case .walletToGoal: return "leaf.circle.fill"
        case .walletToExpense: return "building.columns.fill"
        }
    }
    var rightColor: Color {
        switch type {
        case .incomeToWallet: return .blue
        case .walletToGoal: return .green
        case .walletToExpense: return .orange
        }
    }
    var title: String {
        switch type {
        case .incomeToWallet: return "Пополнение"
        case .walletToGoal: return "Цель"
        case .walletToExpense: return "Расход"
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: d).capitalized
    }
    func dateSpecial(_ d: Date) -> String? {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Сегодня" }
        if cal.isDateInYesterday(d) { return "Вчера" }
        return nil
    }
    var body: some View {
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
            Spacer().frame(height: 8)
            Text("Сумма")
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
                Text("₸")
                    .font(.system(size: 32, weight: .bold))
            }
            .padding(.bottom, 8)
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
                Text("Дата")
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
                        Text("Выберите дату")
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
                    Spacer()
                }
                .presentationDetents([.medium, .large])
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Комментарий")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                TextField("Комментарий", text: $comment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.vertical, 8)
            Spacer()
            Button(action: {
                onConfirm(amount, date, comment)
            }) {
                Text("Сохранить")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .cornerRadius(24)
        .ignoresSafeArea(edges: .bottom)
    }
} 