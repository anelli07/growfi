import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @State private var searchText: String = ""
    @State private var showPeriodPicker = false

    // Фильтрация по периоду
    var filteredTransactions: [Transaction] {
        let range = historyVM.periodVM.currentRange
        let calendar = Calendar.current
        let periodFiltered = historyVM.transactions.filter { tx in
            let txDay = calendar.startOfDay(for: tx.date)
            let startDay = calendar.startOfDay(for: range.start)
            let endDay = calendar.startOfDay(for: range.end)
            return txDay >= startDay && txDay <= endDay
        }
        let sorted = periodFiltered.sorted { $0.date > $1.date }
        if searchText.isEmpty { return sorted }
        return sorted.filter { transaction in
            let searchLower = searchText.lowercased()
            return transaction.title.lowercased().contains(searchLower) ||
                   (transaction.note ?? "").lowercased().contains(searchLower) ||
                   String(format: "%.0f", transaction.amount).contains(searchLower) ||
                   transaction.wallet_name.lowercased().contains(searchLower) ||
                   transaction.icon.lowercased().contains(searchLower)
        }
    }

    // Группировка по дням
    var groupedDays: [TransactionDay] {
        let grouped = Dictionary(grouping: filteredTransactions) { tx in
            Calendar.current.startOfDay(for: tx.date)
        }
        .map { (date, txs) in
            TransactionDay(id: Int(date.timeIntervalSince1970), date: date, transactions: txs)
        }
        .sorted { $0.date > $1.date }
        return grouped
    }

    @ObservedObject private var langManager = AppLanguageManager.shared
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func formattedPeriod(_ period: String) -> String {
        // Ожидается формат типа "Июль 2025" или "July 2025"
        let comps = period.split(separator: " ")
        guard comps.count == 2 else { return period }
        let month = String(comps[0])
        let year = String(comps[1])
        // Пробуем локализовать месяц
        let localizedMonth = NSLocalizedString(month, comment: "")
        return "\(localizedMonth) \(year)"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let lang = AppLanguageManager.shared.currentLanguage.rawValue
        let locale = Locale(identifier: lang)
        let df = DateFormatter()
        df.locale = locale
        df.setLocalizedDateFormatFromTemplate("d MMMM yyyy, EEEE")
        return df.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Верхняя панель
            HStack {
                Text("History".localized)
                    .font(.largeTitle).bold()
                Spacer()
                // Кнопка фильтра удалена
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // Поиск
            SearchBar(placeholder: "search_notes".localized, text: $searchText)
                .padding(.horizontal)
                .padding(.top, 8)
                .keyboardToolbar {
                    hideKeyboard()
                }

            // Новый выбор периода
            Button(action: { showPeriodPicker = true }) {
                HStack(spacing: 4) {
                    Text(formattedPeriod(historyVM.periodVM.formatted))
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 6)
            }
            .padding(.top, 8)

            // Список транзакций
            List {
                // Блок баланса
                Section {
                    BalanceCard(
                        balance: filteredTransactions.reduce(0) { sum, transaction in
                            switch transaction.type {
                            case .income:
                                return sum + transaction.amount
                            case .expense, .goal_transfer:
                                return sum - abs(transaction.amount)
                            case .wallet_transfer, .goal:
                                return sum
                            }
                        },
                        income: filteredTransactions.filter { $0.type == .income }.map { $0.amount }.reduce(0, +),
                        expense: filteredTransactions.filter { $0.type == .expense || $0.type == .goal_transfer }.map { abs($0.amount) }.reduce(0, +),
                        currency: "₸"
                    )
                    .padding(.horizontal)
                    .padding(.top, 12)
                }

                // Заголовок списка операций
                Section {
                    HStack {
                        Text("OperationsList".localized)
                            .font(.headline)
                        Spacer()
                        if !searchText.isEmpty {
                            Text("\(filteredTransactions.count) \(filteredTransactions.count == 1 ? "result".localized : "results".localized)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }

                // Список транзакций
                ForEach(groupedDays) { day in
                    Section(header: 
                        HStack {
                            Text(formattedDate(day.date))
                                .font(.subheadline).bold()
                            Spacer()
                            Text("\(day.total >= 0 ? "+" : "-")\(Int(abs(day.total)))")
                                .font(.subheadline)
                                .foregroundColor(day.total >= 0 ? .green : .red)
                        }
                        .padding(.bottom, 2)
                    ) {
                        ForEach(day.transactions) { tx in
                            TransactionCell(transaction: tx) {
                                print("HistoryView: Delete callback for transaction ID: \(tx.id)")
                                historyVM.deleteTransaction(id: tx.id)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .frame(maxHeight: .infinity)
        }
        .background(Color.white.ignoresSafeArea())
        .hideKeyboardOnTap()
        .sheet(isPresented: $showPeriodPicker) {
            PeriodPicker(selected: $historyVM.periodVM.selectedPeriod, customRange: $historyVM.periodVM.customRange)
        }
        .onLanguageChange()
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView().environmentObject(GoalsViewModel())
    }
}
