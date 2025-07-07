import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var showPeriodPicker = false

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
            SearchBar(placeholder: "Поиск по примечаниям", onTap: {})
                .padding(.horizontal)
                .padding(.top, 8)

            // Период и стрелки
            HStack {
                Button(action: {
                    viewModel.selectPreviousPeriod()
                }) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Button(action: {
                    showPeriodPicker = true
                }) {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedPeriod.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.black)
                }

                Spacer()

                Button(action: {
                    viewModel.selectNextPeriod()
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)

            // Блок баланса
            BalanceCard(
                balance: viewModel.transactions.map { $0.amount }.reduce(0, +),
                income: viewModel.transactions.filter { $0.type == .income }.map { $0.amount }.reduce(0, +),
                expense: abs(viewModel.transactions.filter { $0.type == .expense }.map { $0.amount }.reduce(0, +)),
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
                    ForEach(viewModel.filteredDays) { day in
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
            PeriodPicker(selected: $viewModel.selectedPeriod)
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
} 
