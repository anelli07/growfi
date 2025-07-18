import SwiftUI

struct LoginView: View {
    var onLogin: (() -> Void)? = nil
    @StateObject private var viewModel = LoginViewModel()
    @State private var showRegisterAlert = false
    @State private var showResetAlert = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            Image(systemName: "leaf.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
                .padding(.bottom, 8)
            Text("growfi".localized)
                .font(.largeTitle).bold()
                .foregroundColor(.green)
                .padding(.bottom, 32)
            VStack(spacing: 16) {
                TextField("email".localized, text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                SecureField("password".localized, text: $viewModel.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                Button("reset_password".localized) {
                    viewModel.resetPassword {
                        showResetAlert = true
                    }
                }
                .font(.footnote)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 8)
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.bottom, 4)
            }
            Button(action: {
                viewModel.login {
                    onLogin?()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(14)
                } else {
                    Text("login".localized)
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            Button("register".localized) {
                viewModel.register {
                    showRegisterAlert = true
                }
            }
            .font(.headline)
            .foregroundColor(.green)
            .padding(.top, 8)
            HStack {
                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
                Text("or".localized).font(.caption).foregroundColor(.gray)
                Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            Button(action: {
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    viewModel.loginWithGoogle(presentingViewController: rootVC) {
                        onLogin?()
                    }
                }
            }) {
                if viewModel.isGoogleLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.green, lineWidth: 1)
                        )
                } else {
                    HStack {
                        Image(systemName: "globe")
                        Text("continue_with_google".localized)
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.green, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .alert(isPresented: $showRegisterAlert) {
            Alert(title: Text("register".localized), message: Text("login".localized), dismissButton: .default(Text("ok".localized)))
        }
        .alert(isPresented: $showResetAlert) {
            Alert(title: Text("reset_password".localized), message: Text("email".localized), dismissButton: .default(Text("ok".localized)))
        }
    }
} 