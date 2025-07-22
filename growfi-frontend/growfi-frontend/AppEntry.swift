import SwiftUI

struct SplashView: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 16) {
                Image("plant_stage_0")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(animate ? 1 : 0.7)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.7), value: animate)
                Text("GrowFi")
                    .font(.largeTitle).bold()
                    .foregroundColor(.green)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(.easeOut(duration: 0.7).delay(0.2), value: animate)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            animate = true
        }
    }
}

enum AppRootScreen {
    case splash, welcome, auth, main
}

struct AppEntry: View {
    @State private var rootScreen: AppRootScreen = .splash
    @StateObject private var langManager = AppLanguageManager.shared
    @StateObject private var goalsViewModel = GoalsViewModel()
    @StateObject private var walletsVM = WalletsViewModel()
    @StateObject private var expensesVM = ExpensesViewModel()
    @StateObject private var incomesVM = IncomesViewModel()
    @StateObject private var categoriesVM = CategoriesViewModel()
    @StateObject private var historyVM = HistoryViewModel()
    @StateObject private var analyticsVM = AnalyticsViewModel()
    @StateObject private var notificationManager = NotificationManager.shared

    private func resetAllViewModels() {
        goalsViewModel.user = nil
        goalsViewModel.goals = []
        walletsVM.wallets = []
        expensesVM.expenses = []
        incomesVM.incomes = []
        categoriesVM.incomeCategories = []
        categoriesVM.expenseCategories = []
        historyVM.transactions = []
    }

    private func determineInitialScreen() {
        let hasLaunched = UserDefaults.standard.bool(forKey: "has_launched_before")
        let accessToken = UserDefaults.standard.string(forKey: "access_token")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { // splash задержка
            if !hasLaunched {
                // Первый запуск: Loading → Welcome → Auth → ContentView
                rootScreen = .welcome
                UserDefaults.standard.set(true, forKey: "has_launched_before")
            } else if accessToken == nil {
                // Нет токена: Loading → Auth → ContentView
                rootScreen = .auth
            } else {
                // Есть токен: Loading → ContentView
                rootScreen = .main
            }
        }
    }
    
    private func setupNotifications() {
        // Запрашиваем разрешение на уведомления при первом входе
        if UserDefaults.standard.bool(forKey: "has_launched_before") {
            notificationManager.requestAuthorization()
        }
    }

    private func handleLogout() {
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        resetAllViewModels()
        rootScreen = .auth
    }
    
    private func handleAccountDeleted() {
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        resetAllViewModels()
        rootScreen = .auth
    }

    var body: some View {
        ZStack {
            Group {
                switch rootScreen {
                case .splash:
                    SplashView()
                        .transition(.opacity)
                                .onAppear {
            determineInitialScreen()
            setupNotifications()
        }
                case .welcome:
                    WelcomeView(onLanguageSelected: {
                        withAnimation { rootScreen = .auth }
                    })
                    .transition(.opacity)
                case .auth:
                    AuthView(onLogin: {
                        withAnimation { rootScreen = .main }
                        historyVM.fetchTransactions()
                    }, goalsViewModel: goalsViewModel)
                    .transition(.opacity)
                case .main:
                    ContentView(onLogout: { 
                        withAnimation { handleLogout() } 
                    })
                        .environmentObject(goalsViewModel)
                        .environmentObject(walletsVM)
                        .environmentObject(expensesVM)
                        .environmentObject(incomesVM)
                        .environmentObject(categoriesVM)
                        .environmentObject(historyVM)
                        .environmentObject(analyticsVM)
                        .onAppear {
                            incomesVM.walletsVM = walletsVM
                            walletsVM.expensesVM = expensesVM
                            walletsVM.goalsVM = goalsViewModel
                            incomesVM.historyVM = historyVM
                            walletsVM.historyVM = historyVM
                            incomesVM.analyticsVM = analyticsVM
                            walletsVM.analyticsVM = analyticsVM
                            expensesVM.analyticsVM = analyticsVM
                            goalsViewModel.expensesVM = expensesVM
                            goalsViewModel.incomesVM = incomesVM
                            goalsViewModel.analyticsVM = analyticsVM
                    
                            goalsViewModel.fetchUser()
                            goalsViewModel.fetchGoals()
                            categoriesVM.fetchCategories()
                            walletsVM.fetchWallets()
                            expensesVM.fetchExpenses()
                            incomesVM.fetchIncomes()
                            historyVM.fetchTransactions()
                        }
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut, value: rootScreen)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LogoutDueTo401"))) { _ in
            // Автоматический выход при 401 ошибке
            handleLogout()
        }
    }
} 

