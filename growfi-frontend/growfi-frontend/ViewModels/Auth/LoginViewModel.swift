import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var isRegistered: Bool = false
    @Published var isResetSent: Bool = false
    @Published var isGoogleLoading: Bool = false

    func login(onSuccess: @escaping () -> Void) {
        isLoading = true
        error = nil
        ApiService.shared.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let token):
                    UserDefaults.standard.set(token, forKey: "access_token")
                    self?.isLoggedIn = true
                    onSuccess()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func register(onSuccess: @escaping () -> Void) {
        isLoading = true
        error = nil
        ApiService.shared.register(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.isRegistered = true
                    onSuccess()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func resetPassword(onSuccess: @escaping () -> Void) {
        isLoading = true
        error = nil
        ApiService.shared.resetPassword(email: email) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.isResetSent = true
                    onSuccess()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func loginWithGoogle(onSuccess: @escaping () -> Void) {
        isGoogleLoading = true
        error = nil
        ApiService.shared.loginWithGoogle { [weak self] result in
            DispatchQueue.main.async {
                self?.isGoogleLoading = false
                switch result {
                case .success(let token):
                    UserDefaults.standard.set(token, forKey: "access_token")
                    self?.isLoggedIn = true
                    onSuccess()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
} 