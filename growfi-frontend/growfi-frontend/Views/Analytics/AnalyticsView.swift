import SwiftUI

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var showPeriodPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Заголовок и фильтр
            HStack {
                Text("Отчет")
                    .font(.largeTitle).bold()
                Spacer()
                Button {
                    // фильтры (опционально)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)

            // Период и стрелки
            HStack {
                Button(action: {
                    viewModel.selectPreviousPeriod()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
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
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)

            // Переключатель графика
            HStack(spacing: 12) {
                Button(action: { viewModel.setChartType(.pie) }) {
                    Image(systemName: "chart.pie.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.chartType == .pie ? .blue : .gray)
                        .padding(8)
                        .background(viewModel.chartType == .pie ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                }
                Button(action: { viewModel.setChartType(.line) }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(viewModel.chartType == .line ? .blue : .gray)
                        .padding(8)
                        .background(viewModel.chartType == .line ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // График
            Group {
                if viewModel.chartType == .line {
                    AnalyticsChartView(data: viewModel.groupedByDay)
                        .frame(height: 220)
                        .padding(.top, 8)
                } else {
                    AnalyticsPieChartView(data: viewModel.filteredCategories)
                        .frame(height: 260)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal)

            // Сводка доходов / расходов / баланса
            AnalyticsSummaryView(
                income: viewModel.incomeTotal,
                expense: viewModel.expenseTotal,
                balance: viewModel.balance
            )
            .padding(.horizontal)
            .padding(.top, 16)

            // Переключатель Доходы / Расходы
            Picker("Тип", selection: $viewModel.selectedType) {
                Text("Доходы").tag(TransactionType.income)
                Text("Расходы").tag(TransactionType.expense)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            // Категории
            AnalyticsCategoryScrollView(categories: viewModel.filteredCategories)
                .padding(.top, 4)
                .padding(.bottom, 24)
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(isPresented: $showPeriodPicker) {
            PeriodPicker(selected: $viewModel.selectedPeriod)
        }
    }
    
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}
