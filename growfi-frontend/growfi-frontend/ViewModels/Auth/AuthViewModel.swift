import Foundation
import Combine
import UIKit

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
    @Published var isGoogleLoading: Bool = false
    @Published var showEmailExistsAlert: Bool = false
    @Published var existingEmail: String = ""
    @Published var isAppleLoading: Bool = false
    // Валидация
    var isEmailValid: Bool { email.contains("@") && email.contains(".") }
    var isPasswordValid: Bool { password.count >= 6 }
    let goalsViewModel: GoalsViewModel // теперь только через init

    init(goalsViewModel: GoalsViewModel) {
        self.goalsViewModel = goalsViewModel
    }
    // MARK: - Auth
    func login(completion: (() -> Void)? = nil) {
        error = nil; isLoading = true
        ApiService.shared.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let access):
                    UserDefaults.standard.set(access, forKey: "access_token")
                    completion?()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
    func register(completion: (() -> Void)? = nil) {
        error = nil; isLoading = true
        ApiService.shared.register(email: email, password: password, fullName: fullName) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.showVerifyScreen = true
                    completion?()
                case .failure(let err):
                    // Проверяем, является ли ошибка связанной с существующим email
                    if err.localizedDescription.contains("already exists") || err.localizedDescription.contains("уже существует") {
                        self?.existingEmail = self?.email ?? ""
                        self?.showEmailExistsAlert = true
                        self?.error = "email_exists_but_not_verified".localized
                    } else {
                        self?.error = err.localizedDescription
                    }
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
                    // Автоматический логин после подтверждения
                    self?.login {
                        self?.goalsViewModel.fetchUser()
                        completion(true)
                    }
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

    func refreshToken(completion: @escaping (Bool) -> Void) {
        guard let refresh = UserDefaults.standard.string(forKey: "refresh_token") else { completion(false); return }
        ApiService.shared.refreshToken(refreshToken: refresh) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let access):
                    UserDefaults.standard.set(access, forKey: "access_token")
                    completion(true)
                case .failure:
                    completion(false)
                }
            }
        }
    }

    func logout(onComplete: (() -> Void)? = nil) {
        guard let refresh = UserDefaults.standard.string(forKey: "refresh_token") else { onComplete?(); return }
        ApiService.shared.logout(refreshToken: refresh) { _ in
            UserDefaults.standard.removeObject(forKey: "access_token")
            UserDefaults.standard.removeObject(forKey: "refresh_token")
            DispatchQueue.main.async {
                onComplete?()
            }
        }
    }
    func loginWithGoogle(presentingViewController: UIViewController, onSuccess: @escaping () -> Void) {
        isGoogleLoading = true
        ApiService.shared.loginWithGoogle(presentingViewController: presentingViewController) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGoogleLoading = false
                switch result {
                case .success(let jwt):
                    UserDefaults.standard.set(jwt, forKey: "access_token")
                    onSuccess()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }

    func loginWithApple(idToken: String, fullName: String? = nil, onSuccess: @escaping () -> Void) {
        isAppleLoading = true
        ApiService.shared.loginWithApple(idToken: idToken, fullName: fullName) { [weak self] result in
            DispatchQueue.main.async {
                self?.isAppleLoading = false
                switch result {
                case .success(let jwt):
                    UserDefaults.standard.set(jwt, forKey: "access_token")
                    onSuccess()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
    func clearFields() {
        email = ""; password = ""; fullName = ""; code = ""; error = nil
    }
    
    func resendCodeForExistingEmail(completion: (() -> Void)? = nil) {
        isLoading = true
        ApiService.shared.resendCode(email: existingEmail) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.showEmailExistsAlert = false
                    self?.showVerifyScreen = true
                    self?.email = self?.existingEmail ?? ""
                    completion?()
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
} 