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
                // Кнопка фильтра удалена
            }
            .padding(.horizontal)
            .padding(.top, 0)

            // Новый выбор периода
            Button(action: { showPeriodPicker = true }) {
                HStack(spacing: 4) {
                    Text(viewModel.periodVM.formatted)
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 6)
            }
            .padding(.top, 8)

            // --- Новый блок: Переключатель Pie/Line и кнопка "Цель" ---
            HStack(spacing: 12) {
                // Button(action: { viewModel.chartType = .pie }) {
                //     Image(systemName: "chart.pie.fill")
                //         .foregroundColor(viewModel.chartType == .pie ? .blue : .gray)
                //         .padding(8)
                //         .background(viewModel.chartType == .pie ? Color.blue.opacity(0.1) : Color.clear)
                //         .clipShape(Circle())
                // }
                // Button(action: { viewModel.chartType = .line }) {
                //     Image(systemName: "chart.line.uptrend.xyaxis")
                //         .foregroundColor(viewModel.chartType == .line ? .blue : .gray)
                //         .padding(8)
                //         .background(viewModel.chartType == .line ? Color.blue.opacity(0.1) : Color.clear)
                //         .clipShape(Circle())
                // }
                Spacer()
                // Удалена кнопка 'Цель'
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // --- График или PieChart ---
            // if false && viewModel.chartType == .line {
            //     AnalyticsChartView(data: viewModel.groupedByDay)
            //         .frame(height: 220)
            //         .padding(.horizontal)
            //         .padding(.top, 8)
            // } else {
                AnalyticsPieChartView(data: viewModel.filteredCategories)
                    .frame(height: 220)
                    .padding(.horizontal)
                    .padding(.top, 8)
            // }

            // Удалён блок баланса (BalanceCard)
            // --- Блок кнопок и иконок в белой карточке ---
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button(action: { viewModel.selectedType = .income }) {
                        Text("Доходы")
                            .font(.subheadline)
                            .foregroundColor(viewModel.selectedType == .income ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedType == .income ? Color.green : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    Button(action: { viewModel.selectedType = .expense }) {
                        Text("Расходы")
                            .font(.subheadline)
                            .foregroundColor(viewModel.selectedType == .expense ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedType == .expense ? Color.green : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    Button(action: { viewModel.selectedType = .goal }) {
                        Text("Цель")
                            .font(.subheadline)
                            .foregroundColor(viewModel.selectedType == .goal ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedType == .goal ? Color.green : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                AnalyticsCategoryScrollView(categories: viewModel.filteredCategories)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
            }
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(isPresented: $showPeriodPicker) {
            PeriodPicker(selected: $viewModel.periodVM.selectedPeriod, customRange: $viewModel.periodVM.customRange)
        }
    }
    
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}
