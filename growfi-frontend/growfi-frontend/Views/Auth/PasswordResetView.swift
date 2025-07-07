import SwiftUI

struct PasswordResetView: View {
    @ObservedObject var vm: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 48)
            Image("Seedling.png")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
                .padding(.bottom, 16)
            Text("Восстановление пароля")
                .font(.title2).bold()
                .padding(.bottom, 8)
            Text("Введите email, на который придёт ссылка для сброса пароля.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            TextField("Email", text: $vm.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.vertical, 18)
                .padding(.horizontal, 16)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(vm.email.isEmpty ? 0.15 : 1), lineWidth: 1.5))
                .padding(.bottom, 8)
            if let error = vm.error {
                Text(error).foregroundColor(.red).font(.caption).padding(.bottom, 8)
            }
            if vm.resetSuccess {
                Text("Письмо отправлено!").foregroundColor(.green).font(.caption).padding(.bottom, 8)
            }
            Button(action: { vm.resetPassword { } }) {
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity).frame(height: 54)
                } else {
                    Text("Отправить ссылку")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(vm.isEmailValid ? Color.green : Color.gray.opacity(0.5))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)
            .disabled(!vm.isEmailValid || vm.isLoading)
            Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.green)
            .font(.subheadline)
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
} 