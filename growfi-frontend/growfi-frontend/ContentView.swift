import SwiftUI

struct ContentView: View {
    @EnvironmentObject var goalsViewModel: GoalsViewModel
    @EnvironmentObject var walletsVM: WalletsViewModel
    @EnvironmentObject var expensesVM: ExpensesViewModel
    @EnvironmentObject var incomesVM: IncomesViewModel
    @EnvironmentObject var historyVM: HistoryViewModel

    var onLogout: () -> Void

    @State private var selectedTab = 2 // Главный экран — 'Цели'

    var body: some View {
        TabView(selection: $selectedTab) {
            HistoryView()
                .environmentObject(historyVM)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("history".localized)
                }
                .tag(0)
            OperationsView()
                .tabItem {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("operations".localized)
                }
                .tag(1)
            GoalsCarouselView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "leaf.circle.fill")
                    Text("goals".localized)
                }
                .tag(2)
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("analytics".localized)
                }
                .tag(3)
            SettingsView(onLogout: onLogout)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("settings".localized)
                }
                .tag(4)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(onLogout: {})
            .environmentObject(GoalsViewModel())
            .environmentObject(WalletsViewModel())
            .environmentObject(ExpensesViewModel())
            .environmentObject(IncomesViewModel())
    }
}


