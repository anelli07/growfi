import SwiftUI

struct EmailCodeVerifyView: View {
    @ObservedObject var vm: AuthViewModel
    var onSuccess: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 48)
            Image("Seedling.png")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90)
                .padding(.bottom, 16)
            Text("email".localized)
                .font(.title2).bold()
                .padding(.bottom, 8)
            Text("enter_code_sent_to_email".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            TextField("code".localized, text: $vm.code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.title2)
                .padding(.vertical, 18)
                .padding(.horizontal, 32)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(vm.code.isEmpty ? 0.15 : 1), lineWidth: 1.5))
                .padding(.bottom, 8)
            if let error = vm.error {
                Text(error).foregroundColor(.red).font(.caption).padding(.bottom, 8)
            }
            Button(action: { 
                vm.verifyCode { success in
                    if success { onSuccess?() }
                }
            }) {
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity).frame(height: 54)
                } else {
                    Text("continue".localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.green)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            if vm.resent {
                Text("continue".localized).foregroundColor(.green).font(.caption)
            }
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
} 