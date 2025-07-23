import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var vm: AuthViewModel
    var onLogin: (() -> Void)? = nil
    @State private var showPassword = false
    @State private var appleSignInCoordinator: AppleSignInCoordinator? = nil

    init(onLogin: (() -> Void)? = nil, goalsViewModel: GoalsViewModel) {
        _vm = StateObject(wrappedValue: AuthViewModel(goalsViewModel: goalsViewModel))
        self.onLogin = onLogin
    }
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 48)
            VStack(spacing: 12) {
                Image("plant_stage_0")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                Text("growfi".localized)
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundColor(Color.green)
            }
            .padding(.bottom, 36)
            VStack(spacing: 20) {
                if !vm.isLogin {
                    TextField("full_name".localized, text: $vm.fullName)
                        .autocapitalization(.words)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(vm.fullName.isEmpty ? 0.15 : 1), lineWidth: 1.5))
                }
                TextField("email".localized, text: $vm.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .foregroundColor(.black)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(vm.email.isEmpty ? 0.15 : 1), lineWidth: 1.5))
                HStack {
                    if showPassword {
                        TextField("password".localized, text: $vm.password)
                            .foregroundColor(.black)
                    } else {
                        SecureField("password".localized, text: $vm.password)
                            .foregroundColor(.black)
                    }
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 16)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(vm.password.isEmpty ? 0.15 : 1), lineWidth: 1.5))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 10)
            Button("reset_password".localized) { vm.showResetSheet = true }
                .font(.subheadline)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 36)
                .padding(.bottom, 8)
            if let error = vm.error {
                Text(error).foregroundColor(.red).font(.caption)
            }
            Button(action: {
                if vm.isLogin {
                    vm.login {
                        onLogin?()
                    }
                } else {
                    vm.register()
                }
            }) {
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity).frame(height: 56)
                } else {
                    Text(vm.isLogin ? "login".localized : "register".localized)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(vm.isEmailValid && vm.isPasswordValid ? Color.green : Color.gray.opacity(0.5))
                        .cornerRadius(16)
                        .font(.headline)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .disabled(!vm.isEmailValid || !vm.isPasswordValid || vm.isLoading)
            Button(vm.isLogin ? "register".localized : "login".localized) {
                vm.isLogin.toggle(); vm.error = nil
            }
            .foregroundColor(.green)
            .font(.headline)
            .padding(.bottom, 18)
            HStack {
                Rectangle().frame(height: 1).foregroundColor(Color(.systemGray4))
                Text("or".localized).foregroundColor(.gray)
                Rectangle().frame(height: 1).foregroundColor(Color(.systemGray4))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 18)
            Button(action: {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    vm.loginWithGoogle(presentingViewController: rootVC) {
                        onLogin?()
                    }
                }
            }) {
                if vm.isGoogleLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "globe").foregroundColor(Color.green)
                        Text("continue_with_google".localized).font(.headline).foregroundColor(Color.green)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray4), lineWidth: 1))
                }
            }
            .padding(.horizontal, 28)
            
            // Кастомная Apple Sign In Button
            Button(action: {
                print("[DEBUG] AppleID button tapped")
                let provider = ASAuthorizationAppleIDProvider()
                let request = provider.createRequest()
                request.requestedScopes = [.fullName, .email]
                let controller = ASAuthorizationController(authorizationRequests: [request])
                let coordinator = AppleSignInCoordinator(vm: vm, onLogin: onLogin)
                controller.delegate = coordinator
                controller.presentationContextProvider = coordinator
                self.appleSignInCoordinator = coordinator
                controller.performRequests()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "applelogo").font(.title2)
                    Text("continue_with_apple".localized).font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onAppear {
            print("[DEBUG] AuthView onAppear!")
        }
        .alert("email_already_exists".localized, isPresented: $vm.showEmailExistsAlert) {
            Button("resend_verification".localized) {
                vm.resendCodeForExistingEmail()
            }
            Button("Cancel", role: .cancel) {
                vm.showEmailExistsAlert = false
            }
        } message: {
            Text("email_exists_but_not_verified".localized)
        }
        .sheet(isPresented: $vm.showResetSheet) {
            PasswordResetView(vm: vm)
        }
        .sheet(isPresented: $vm.showVerifyScreen) {
            EmailCodeVerifyView(vm: vm, onSuccess: {
                onLogin?()
            })
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView(goalsViewModel: GoalsViewModel())
    }
} 

class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let vm: AuthViewModel
    let onLogin: (() -> Void)?
    init(vm: AuthViewModel, onLogin: (() -> Void)?) {
        self.vm = vm
        self.onLogin = onLogin
    }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        return ASPresentationAnchor()
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("[DEBUG] AppleSignInCoordinator didCompleteWithAuthorization")
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let identityToken = appleIDCredential.identityToken,
           let idTokenString = String(data: identityToken, encoding: .utf8) {
            print("[DEBUG] AppleID identityToken: \(idTokenString.prefix(40))...")
            let fullName = appleIDCredential.fullName?.formatted()
            vm.loginWithApple(idToken: idTokenString, fullName: fullName) {
                self.onLogin?()
            }
        } else {
            print("[DEBUG] AppleID identityToken is nil")
        }
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("[DEBUG] AppleSignInCoordinator didCompleteWithError: \(error.localizedDescription)")
        vm.error = error.localizedDescription
    }
} 
