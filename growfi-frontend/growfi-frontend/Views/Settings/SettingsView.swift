import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    @State private var showProfile = false
    @State private var isLoggedOut = false
    @StateObject private var loginVM = LoginViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("Настройки")
                .font(.title2).bold()
            Button(action: { showProfile.toggle() }) {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text(goalsVM.user?.name ?? "Имя не указано")
                            .font(.headline)
                        Text(goalsVM.user?.email ?? "Логин не указан")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)
            }
            .sheet(isPresented: $showProfile) {
                VStack(spacing: 16) {
                    Text("Профиль")
                        .font(.title2).bold()
                    Text("Имя: \(goalsVM.user?.name ?? "-")")
                    Text("Логин: \(goalsVM.user?.email ?? "-")")
                    Spacer()
                }
                .padding()
            }
            Button(action: {
                loginVM.logout {
                    isLoggedOut = true
                }
            }) {
                Text("Выйти")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
            }
            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $isLoggedOut) {
            AuthView(onLogin: { isLoggedOut = false })
                .environmentObject(AuthViewModel())
        }       
    }
} 