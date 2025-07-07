import Foundation
import Combine

class AuthViewModel: ObservableObject {
    // Input
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var fullName: String = ""
    @Published var code: String = ""
    @Published var isLogin: Bool = true
    // State
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var showVerifyScreen: Bool = false
    @Published var showResetSheet: Bool = false
    @Published var resentSuccess: Bool = false
    @Published var resetSuccess: Bool = false
    @Published var resent: Bool = false
    // Валидация
    var isEmailValid: Bool { email.contains("@") && email.contains(".") }
    var isPasswordValid: Bool { password.count >= 6 }
    // MARK: - Auth
    func login(completion: @escaping (Bool) -> Void) {
        error = nil; isLoading = true
        ApiService.shared.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.clearFields()
                    completion(true)
                case .failure(let err):
                    self?.error = err.localizedDescription
                    completion(false)
                }
            }
        }
    }
    func register(completion: @escaping (Bool) -> Void) {
        error = nil; isLoading = true
        ApiService.shared.register(email: email, password: password, fullName: fullName) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.showVerifyScreen = true
                    completion(true)
                case .failure(let err):
                    self?.error = err.localizedDescription
                    completion(false)
                }
            }
        }
    }
    func verifyCode(completion: @escaping (Bool) -> Void) {
        error = nil; isLoading = true
        ApiService.shared.verifyCode(email: email, code: code) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.showVerifyScreen = false
                    self?.isLogin = true
                    completion(true)
                case .failure(let err):
                    self?.error = err.localizedDescription
                    completion(false)
                }
            }
        }
    }
    func resendCode(completion: (() -> Void)? = nil) {
        error = nil; isLoading = true
        ApiService.shared.resendCode(email: email) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.resent = true
                    self?.resentSuccess = true
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
                completion?()
            }
        }
    }
    func resetPassword(completion: (() -> Void)? = nil) {
        error = nil; isLoading = true
        ApiService.shared.resetPassword(email: email) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.resetSuccess = true
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
                completion?()
            }
        }
    }
    func clearFields() {
        email = ""; password = ""; fullName = ""; code = ""; error = nil
    }
} 