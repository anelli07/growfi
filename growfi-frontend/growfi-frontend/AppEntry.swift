import SwiftUI

struct AppEntry: View {
    @State private var isLoggedIn = UserDefaults.standard.string(forKey: "access_token") != nil

    var body: some View {
        if isLoggedIn {
            ContentView()
        } else {
            AuthViewWrapper(isLoggedIn: $isLoggedIn)
        }
    }
}

struct AuthViewWrapper: View {
    @Binding var isLoggedIn: Bool
    var body: some View {
        AuthView(onLogin: {
            isLoggedIn = true
        })
    }
} 