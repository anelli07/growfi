import SwiftUI
import AuthenticationServices

@available(iOS 13.0, *)
struct AppleSignInButton: View {
    let onSignIn: () -> Void
    
    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(let authResults):
                    onSignIn()
                case .failure(let error):
                    // Handle error silently
                    break
                }
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(8)
    }
}

@available(iOS 13.0, *)
struct AppleSignInButton_Previews: PreviewProvider {
    static var previews: some View {
        AppleSignInButton {
            // Handle sign in
        }
        .padding()
    }
} 