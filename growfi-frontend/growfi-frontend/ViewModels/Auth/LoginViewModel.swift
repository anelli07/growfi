import Foundation
import Combine
import UIKit

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
                case .success(let access):
                    UserDefaults.standard.set(access, forKey: "access_token")
                    self?.clearFields()
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

    func loginWithApple(idToken: String, onSuccess: @escaping () -> Void) {
        isLoading = true
        ApiService.shared.loginWithApple(idToken: idToken) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
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
                self.isLoggedIn = false
                onComplete?()
            }
        }
    }
    
    func clearFields() {
        email = ""
        password = ""
        error = nil
    }
} 