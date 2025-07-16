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

struct AppEntry: View {
    @State private var isLoggedIn = UserDefaults.standard.string(forKey: "access_token") != nil
    @State private var triedRefresh = false
    @StateObject private var goalsViewModel = GoalsViewModel()
    @StateObject private var walletsVM = WalletsViewModel()
    @StateObject private var expensesVM = ExpensesViewModel()
    @StateObject private var incomesVM = IncomesViewModel()
    @StateObject private var categoriesVM = CategoriesViewModel()
    @StateObject private var historyVM = HistoryViewModel()
    @State private var showSplash = true

    init() {
        // incomesVM.walletsVM = walletsVM // This line is moved to onAppear
    }

    var body: some View {
        ZStack {
            Group {
                if isLoggedIn {
                    ContentView()
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
                } else if !triedRefresh, let refresh = UserDefaults.standard.string(forKey: "refresh_token") {
                    ProgressView().onAppear {
                        ApiService.shared.refreshToken(refreshToken: refresh) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let access):
                                    UserDefaults.standard.set(access, forKey: "access_token")
                                    print("[AppEntry] Новый access_token после refresh:", access)
                                    isLoggedIn = true
                                case .failure:
                                    UserDefaults.standard.removeObject(forKey: "access_token")
                                    UserDefaults.standard.removeObject(forKey: "refresh_token")
                                    isLoggedIn = false
                                }
                                triedRefresh = true
                            }
                        }
                    }
                } else {
                    AuthView(onLogin: {
                        isLoggedIn = true
                        historyVM.fetchTransactions()
                    }, goalsViewModel: goalsViewModel)
                }
            }
            .opacity(showSplash ? 0 : 1)
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("LogoutDueTo401"), object: nil, queue: .main) { _ in
                UserDefaults.standard.removeObject(forKey: "access_token")
                UserDefaults.standard.removeObject(forKey: "refresh_token")
                isLoggedIn = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
} 

