import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 2 // Главный экран — 'Цели'

    var body: some View {
        TabView(selection: $selectedTab) {
            HistoryView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("История")
                }
                .tag(0)
            OperationsView()
                .tabItem {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Операции")
                }
                .tag(1)
            GoalsCarouselView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "leaf.circle.fill")
                    Text("Цели")
                }
                .tag(2)
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Аналитика")
                }
                .tag(3)
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Настройки")
                }
                .tag(4)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GoalsViewModel())
    }
}


