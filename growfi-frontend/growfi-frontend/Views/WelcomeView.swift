import SwiftUI
import UserNotifications
import Network

struct WelcomeView: View {
    @ObservedObject var langManager = AppLanguageManager.shared
    @State private var selectedLanguage: AppLanguage = AppLanguageManager.shared.currentLanguage
    var onLanguageSelected: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.2), Color.white]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                Image("plant_stage_3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .shadow(radius: 10)
                Text("growfi".localized)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .padding(.top, 8)
                Text("welcome".localized)
                    .font(.title2)
                    .foregroundColor(.primary)
                Text("choose_language".localized)
                    .font(.headline)
                    .foregroundColor(.secondary)
                HStack(spacing: 20) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button(action: {
                            selectedLanguage = lang
                            langManager.currentLanguage = lang
                        }) {
                            Text(lang.displayName)
                                .font(.headline)
                                .foregroundColor(selectedLanguage == lang ? .white : .green)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 28)
                                .background(selectedLanguage == lang ? Color.green : Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                        }
                        .shadow(color: selectedLanguage == lang ? Color.green.opacity(0.2) : .clear, radius: 6, x: 0, y: 2)
                    }
                }
                Button(action: {
                    langManager.currentLanguage = selectedLanguage
                    requestPermissionsAndContinue()
                }) {
                    Text("continue".localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 60)
                        .background(Color.green)
                        .cornerRadius(20)
                        .shadow(radius: 8, y: 4)
                }
                .padding(.top, 10)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func requestPermissionsAndContinue() {
        // Сначала запрашиваем разрешение на уведомления
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                print("[WelcomeView] Notification permission granted: \(granted)")
                
                // Затем проверяем сеть (в iOS это обычно всегда доступно)
                let monitor = NWPathMonitor()
                monitor.pathUpdateHandler = { path in
                    DispatchQueue.main.async {
                        print("[WelcomeView] Network status: \(path.status)")
                        monitor.cancel()
                        
                        // Переходим к следующему экрану
                        onLanguageSelected?()
                    }
                }
                let queue = DispatchQueue(label: "NetworkCheck")
                monitor.start(queue: queue)
            }
        }
    }
}

 
