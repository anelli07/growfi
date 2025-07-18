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
    // Временно сбрасываем флаг для тестирования экрана выбора языка
    UserDefaults.standard.removeObject(forKey: "has_launched_before")
    
    let hasLaunched = UserDefaults.standard.bool(forKey: "has_launched_before")
    let accessToken = UserDefaults.standard.string(forKey: "access_token")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { // splash задержка
        if !hasLaunched {
            rootScreen = .welcome
            UserDefaults.standard.set(true, forKey: "has_launched_before")
        } else if accessToken == nil {
            rootScreen = .auth
        } else {
            rootScreen = .main
        }
    }
}

    private func handleLogout() {
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
                    ContentView(onLogout: { withAnimation { handleLogout() } })
                        .environmentObject(goalsViewModel)
                        .environmentObject(walletsVM)
                        .environmentObject(expensesVM)
                        .environmentObject(incomesVM)
                        .environmentObject(categoriesVM)
                        .environmentObject(historyVM)
                        .onAppear {
                            incomesVM.walletsVM = walletsVM
                            walletsVM.expensesVM = expensesVM
                            walletsVM.goalsVM = goalsViewModel
                            incomesVM.historyVM = historyVM
                            walletsVM.historyVM = historyVM
                            goalsViewModel.expensesVM = expensesVM
                            goalsViewModel.incomesVM = incomesVM
                            let token = UserDefaults.standard.string(forKey: "access_token") ?? "nil"
                            print("[AppEntry] access_token при старте:", token)
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
    }
} 

