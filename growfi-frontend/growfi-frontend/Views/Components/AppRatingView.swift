import SwiftUI

struct AppRatingView: View {
    @Binding var isPresented: Bool
    @State private var selectedRating: Int = 0
    @State private var isSubmitting = false
    @State private var showThankYou = false
    @State private var showAppStorePrompt = false
    
    var body: some View {
        ZStack {
            // Полупрозрачный фон
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isSubmitting {
                        isPresented = false
                    }
                }
            
            // Основное окно
            VStack(spacing: 24) {
                // Заголовок
                VStack(spacing: 8) {
                    Text("rate_app".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("rate_app_message".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Звездочки
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            selectedRating = star
                        }) {
                            Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(star <= selectedRating ? .yellow : .gray)
                                .scaleEffect(star <= selectedRating ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedRating)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Кнопки
                VStack(spacing: 12) {
                    Button(action: {
                        submitRating()
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Text("submit_rating".localized)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedRating > 0 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedRating == 0 || isSubmitting)
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("maybe_later".localized)
                            .foregroundColor(.secondary)
                    }
                    .disabled(isSubmitting)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
            .scaleEffect(showThankYou ? 0.9 : 1.0)
            .opacity(showThankYou ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: showThankYou)
        }
        .transition(.opacity.combined(with: .scale))
        .alert("rate_in_appstore".localized, isPresented: $showAppStorePrompt) {
            Button("rate_now".localized) {
                openAppStore(isPresented: $isPresented)
            }
            Button("maybe_later".localized, role: .cancel) {
                isPresented = false
            }
        } message: {
            Text("rate_in_appstore_message".localized)
        }
    }
    
    private func submitRating() {
        guard selectedRating > 0 else { return }
        
        isSubmitting = true
        
        // Сохраняем оценку локально
        RatingService.shared.saveRatingLocally(rating: selectedRating)
        
        // Отправляем оценку на сервер
        RatingService.shared.submitRating(rating: selectedRating) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                
                switch result {
                case .success:
                    showThankYou = true
                    
                    // Отмечаем, что пользователь оценил приложение
                    AppRatingManager.shared.markAsRated()
                    
                    // Показываем благодарность
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        // Если высокая оценка - предлагаем оценить в App Store
                        if selectedRating >= 4 {
                            showAppStorePrompt = true
                        } else {
                            isPresented = false
                        }
                    }
                    
                case .failure(let error):
                    print("Error submitting rating: \(error)")
                    // Даже при ошибке отмечаем как оцененное
                    AppRatingManager.shared.markAsRated()
                    isPresented = false
                }
            }
        }
            }
    }
    
    private func openAppStore(isPresented: Binding<Bool>) {
        // App Store ID для GrowFi: Finance Manager
        let appStoreId = "6748830339"
        if let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review") {
            UIApplication.shared.open(url)
        }
        // Закрываем окно после открытия App Store
        DispatchQueue.main.async {
            isPresented.wrappedValue = false
        }
    }
    
    #Preview {
        AppRatingView(isPresented: .constant(true))
    } 