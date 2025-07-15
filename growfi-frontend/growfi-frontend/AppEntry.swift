import SwiftUI

struct AppEntry: View {
    @State private var isLoggedIn = UserDefaults.standard.string(forKey: "access_token") != nil
    @State private var triedRefresh = false
    @StateObject private var goalsViewModel = GoalsViewModel()
    @StateObject private var walletsVM = WalletsViewModel()
    @StateObject private var expensesVM = ExpensesViewModel()
    @StateObject private var incomesVM = IncomesViewModel()
    @StateObject private var categoriesVM = CategoriesViewModel()
    @StateObject private var historyVM = HistoryViewModel()

    init() {
        // incomesVM.walletsVM = walletsVM // This line is moved to onAppear
    }

    var body: some View {
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
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("LogoutDueTo401"), object: nil, queue: .main) { _ in
                UserDefaults.standard.removeObject(forKey: "access_token")
                UserDefaults.standard.removeObject(forKey: "refresh_token")
                isLoggedIn = false
            }
        }
    }
} 

