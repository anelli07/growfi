import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @State private var searchText: String = ""
    @State private var selectedPeriod: PeriodType = .month
    @State private var showPeriodPicker = false

    // Фильтрация по периоду
    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        let periodFiltered = viewModel.transactions.filter { tx in
            switch selectedPeriod {
            case .month:
                return calendar.isDate(tx.date, equalTo: now, toGranularity: .month)
            case .week:
                return calendar.isDate(tx.date, equalTo: now, toGranularity: .weekOfYear)
            case .year:
                return calendar.isDate(tx.date, equalTo: now, toGranularity: .year)
            case .quarter, .halfYear, .all, .custom:
                return true // MVP
            }
        }
        let sorted = periodFiltered.sorted { $0.date > $1.date }
        if searchText.isEmpty { return sorted }
        return sorted.filter {
            $0.category.lowercased().contains(searchText.lowercased()) ||
            ($0.note ?? "").lowercased().contains(searchText.lowercased())
        }
    }

    // Группировка по дням
    var groupedDays: [TransactionDay] {
        let grouped = Dictionary(grouping: filteredTransactions) { tx in
            Calendar.current.startOfDay(for: tx.date)
        }
        .map { (date, txs) in
            TransactionDay(date: date, transactions: txs)
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
                Button {
                    showPeriodPicker = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // Поиск
            SearchBar(placeholder: "Поиск по примечаниям", text: $searchText)
                .padding(.horizontal)
                .padding(.top, 8)

            // Период и стрелки
            HStack {
                Button(action: {
                    selectPreviousPeriod()
                }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Button(action: {
                    showPeriodPicker = true
                }) {
                    HStack(spacing: 4) {
                        Text(selectedPeriod.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.black)
                }

                Spacer()

                Button(action: {
                    selectNextPeriod()
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)

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
            PeriodPicker(selected: $selectedPeriod)
        }
    }

    // Периоды
    func selectPreviousPeriod() {
        guard let currentIndex = PeriodType.allCases.firstIndex(of: selectedPeriod),
              currentIndex > 0 else { return }
        let newPeriod = PeriodType.allCases[currentIndex - 1]
        selectedPeriod = newPeriod
    }
    func selectNextPeriod() {
        guard let currentIndex = PeriodType.allCases.firstIndex(of: selectedPeriod),
              currentIndex < PeriodType.allCases.count - 1 else { return }
        let newPeriod = PeriodType.allCases[currentIndex + 1]
        selectedPeriod = newPeriod
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView().environmentObject(GoalsViewModel())
    }
}
