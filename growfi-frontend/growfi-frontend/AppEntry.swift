import SwiftUI

struct AppEntry: View {
    @State private var isLoggedIn = UserDefaults.standard.string(forKey: "access_token") != nil
    @State private var triedRefresh = false
    @StateObject private var goalsViewModel = GoalsViewModel()
    @StateObject private var walletsVM = WalletsViewModel()
    @StateObject private var expensesVM = ExpensesViewModel()

    var body: some View {
        Group {
            if isLoggedIn {
                ContentView()
                    .environmentObject(goalsViewModel)
                    .environmentObject(walletsVM)
                    .environmentObject(expensesVM)
            } else if !triedRefresh, let refresh = UserDefaults.standard.string(forKey: "refresh_token") {
                ProgressView().onAppear {
                    ApiService.shared.refreshToken(refreshToken: refresh) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let access):
                                UserDefaults.standard.set(access, forKey: "access_token")
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
                AuthView(onLogin: { isLoggedIn = true }, goalsViewModel: goalsViewModel)
            }
        }
    }
} 

