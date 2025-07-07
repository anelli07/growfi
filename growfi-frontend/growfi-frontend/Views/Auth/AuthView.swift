import SwiftUI

struct AuthView: View {
    @StateObject private var vm = AuthViewModel()
    var onLogin: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 48)
            VStack(spacing: 12) {
                Image("Seedling.png")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                Text("GrowFi")
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundColor(Color.green)
            }
            .padding(.bottom, 36)
            VStack(spacing: 20) {
                if !vm.isLogin {
                    TextField("Имя", text: $vm.fullName)
                        .autocapitalization(.words)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(vm.fullName.isEmpty ? 0.15 : 1), lineWidth: 1.5))
                }
                TextField("Email", text: $vm.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(vm.email.isEmpty ? 0.15 : 1), lineWidth: 1.5))
                SecureField("Пароль", text: $vm.password)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(vm.password.isEmpty ? 0.15 : 1), lineWidth: 1.5))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 10)
            Button("Восстановить пароль") { vm.showResetSheet = true }
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
                    vm.login { success in
                        if success { onLogin?() }
                    }
                } else {
                    vm.register { _ in }
                }
            }) {
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity).frame(height: 56)
                } else {
                    Text(vm.isLogin ? "Войти" : "Зарегистрироваться")
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
            Button(vm.isLogin ? "Регистрация" : "Войти") {
                vm.isLogin.toggle(); vm.error = nil
            }
            .foregroundColor(.green)
            .font(.headline)
            .padding(.bottom, 18)
            HStack {
                Rectangle().frame(height: 1).foregroundColor(Color(.systemGray4))
                Text("или").foregroundColor(.gray)
                Rectangle().frame(height: 1).foregroundColor(Color(.systemGray4))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 18)
            Button(action: { }) {
                HStack(spacing: 10) {
                    Image(systemName: "globe").foregroundColor(Color.green)
                    Text("Continue with Google").font(.headline).foregroundColor(Color.green)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray4), lineWidth: 1))
            }
            .padding(.horizontal, 28)
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
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
        AuthView()
    }
} 
