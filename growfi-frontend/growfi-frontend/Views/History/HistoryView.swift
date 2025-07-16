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
        return sorted.filter {
            ($0.title.lowercased().contains(searchText.lowercased())) ||
            ($0.note ?? "").lowercased().contains(searchText.lowercased())
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

    var body: some View {
        VStack(spacing: 0) {
            // Верхняя панель
            HStack {
                Text("История")
                    .font(.largeTitle).bold()
                Spacer()
                // Кнопка фильтра удалена
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // Поиск
            SearchBar(placeholder: "Поиск по примечаниям", text: $searchText)
                .padding(.horizontal)
                .padding(.top, 8)

            // Новый выбор периода
            Button(action: { showPeriodPicker = true }) {
                HStack(spacing: 4) {
                    Text(historyVM.periodVM.formatted)
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 6)
            }
            .padding(.top, 8)

            // Блок баланса
            BalanceCard(
                balance: filteredTransactions.map { $0.amount }.reduce(0, +),
                income: filteredTransactions.filter { $0.type == .income }.map { $0.amount }.reduce(0, +),
                expense: abs(filteredTransactions.filter { $0.type == .expense }.map { $0.amount }.reduce(0, +)),
                currency: "₸"
            )
            .padding(.horizontal)
            .padding(.top, 12)

            // Заголовок списка операций
            HStack {
                Text("Список операций")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // Транзакции
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(groupedDays) { day in
                        TransactionDaySection(day: day)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(isPresented: $showPeriodPicker) {
            PeriodPicker(selected: $historyVM.periodVM.selectedPeriod, customRange: $historyVM.periodVM.customRange)
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView().environmentObject(GoalsViewModel())
    }
}
