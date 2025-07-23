import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var goalsVM: GoalsViewModel
    @StateObject private var loginVM = LoginViewModel()
    @ObservedObject var langManager = AppLanguageManager.shared
    var onLogout: () -> Void
    @State private var showLanguageSheet = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var showAccountDeletedAlert = false
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("settings".localized.capitalized)
                        .font(.largeTitle).bold()
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .padding(.horizontal)
                    // Профиль (на всю ширину)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goalsVM.user?.full_name ?? "full_name".localized)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(goalsVM.user?.email ?? "email".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    // Язык
                    Button(action: { showLanguageSheet = true }) {
                        HStack {
                            Text("language".localized)
                            Spacer()
                            Text(langManager.currentLanguage.displayName)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    // Legal (заголовок вынесен)
                    Text("legal".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                    VStack(spacing: 0) {
                        if langManager.currentLanguage == .ru {
                            Link("privacy_policy".localized, destination: URL(string: "https://docs.google.com/document/d/1A6j_rbcnJxfKa8EuVrSXmwD1SAFTVT0hNi_J3j_1bnk/edit?tab=t.0")!)
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                            Divider().padding(.leading)
                            Link("terms_and_conditions".localized, destination: URL(string: "https://docs.google.com/document/d/1ZdSp24--D5_YP3DMHljmuUbXlo99jiMezs2jj5GhyBM/edit?tab=t.0")!)
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                        } else {
                            Link("privacy_policy_en".localized, destination: URL(string: "https://docs.google.com/document/d/1uNAUnFUbZJ9EOkoUymDY1Nl8iPszRx03k_2kCKRMO6I/edit?tab=t.0")!)
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                            Divider().padding(.leading)
                            Link("terms_and_conditions_en".localized, destination: URL(string: "https://docs.google.com/document/d/1O1VpJVU7cdOAbrwNAtD0o_8TS7vwDAVchEeEG2bj2yg/edit?tab=t.0")!)
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Уведомления
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("notifications".localized)
                                .font(.headline)
                            Spacer()
                            if notificationManager.isAuthorized {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "bell.slash")
                                    .foregroundColor(.gray)
                            }
                        }
                        if !notificationManager.isAuthorized {
                            Button("enable_notifications".localized) {
                                notificationManager.requestAuthorization()
                            }
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        } else {
                            Toggle("notifications".localized, isOn: Binding(
                                get: { notificationManager.isSystemNotificationsEnabled },
                                set: { notificationManager.isSystemNotificationsEnabled = $0 }
                            ))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Logout
                    Button(action: {
                        loginVM.logout {
                            goalsVM.user = nil
                            onLogout()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("logout".localized)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .padding(.top, 8)
                    
                    // Delete Account
                    Button(action: { showDeleteAccountAlert = true }) {
                        HStack {
                            Spacer()
                            if isDeletingAccount {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.red)
                            } else {
                                Text("delete_account".localized)
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .disabled(isDeletingAccount)
                    .padding(.top, 4)
                    

                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
            .actionSheet(isPresented: $showLanguageSheet) {
                ActionSheet(title: Text("language".localized), buttons: AppLanguage.allCases.map { lang in
                    .default(Text(lang.displayName)) {
                        langManager.currentLanguage = lang
                    }
                } + [.cancel()])
            }
            .alert("delete_account_title".localized, isPresented: $showDeleteAccountAlert) {
                Button("delete_account".localized, role: .destructive) {
                    deleteAccount()
                }
                Button("cancel".localized, role: .cancel) { }
            } message: {
                Text("delete_account_confirmation".localized)
            }
            .alert("account_deleted".localized, isPresented: $showAccountDeletedAlert) {
                Button("ok".localized) {
                    // Очищаем все данные пользователя
                    UserDefaults.standard.removeObject(forKey: "access_token")
                    UserDefaults.standard.removeObject(forKey: "refresh_token")
                    UserDefaults.standard.removeObject(forKey: "apple_id")
                    UserDefaults.standard.removeObject(forKey: "google_id")
                    goalsVM.user = nil
                    // Вызываем onLogout для перехода на экран авторизации
                    onLogout()
                }
            } message: {
                Text("account_deleted_message".localized)
            }
            .onLanguageChange()
        }
    }
    
    private func deleteAccount() {
        guard let token = UserDefaults.standard.string(forKey: "access_token") else { return }
        
        isDeletingAccount = true
        
        ApiService.shared.deleteAccount(token: token) { result in
            DispatchQueue.main.async {
                isDeletingAccount = false
                
                switch result {
                case .success:
                    // Показываем уведомление об успешном удалении
                    showAccountDeletedAlert = true
                case .failure(_):
                    // Можно показать алерт с ошибкой
                    break
                }
            }
        }
    }
}
