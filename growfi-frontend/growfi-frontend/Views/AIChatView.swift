import SwiftUI

struct AIChatView: View {
    @StateObject private var aiVM = AIViewModel()
    @State private var messageText = ""
    @State private var showAnalysis = false
    @State private var analysisText = ""
    @FocusState private var isInputFocused: Bool
    
    let suggestions = [
        "Добавить расходы?",
        "Как быстрее накопить?",
        "Анализ расходов?",
        "Совет по бюджету",
        "Сколько я трачу на еду?",
        "Как сэкономить?"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Text("AI Помощник")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Анализ") {
                    showAnalysis = true
                }
                .foregroundColor(.green)
            }
            .padding(.horizontal)
            .padding(.top, 24) // увеличенный отступ сверху
            // Сообщения
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(aiVM.messages) { message in
                        MessageBubble(message: message)
                    }
                    if aiVM.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("AI думает...")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)
            }
            // Подсказки — теперь внизу
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            messageText = suggestion
                        }) {
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
            // Поле ввода
            HStack {
                TextField("Напишите сообщение...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(aiVM.isLoading)
                    .focused($isInputFocused)
                Button(action: sendMessage) {
                    Image("поисковик")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                        .opacity(messageText.isEmpty || aiVM.isLoading ? 0.4 : 1.0)
                }
                .disabled(messageText.isEmpty || aiVM.isLoading)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .alert("Ошибка", isPresented: .constant(aiVM.error != nil)) {
            Button("OK") {
                aiVM.error = nil
            }
        } message: {
            Text(aiVM.error ?? "")
        }
        .sheet(isPresented: $showAnalysis) {
            AnalysisView(analysisText: $analysisText) {
                aiVM.analyzeExpenses { result in
                    analysisText = result
                }
            }
        }
        .onAppear {
            // Автофокус только при открытии sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isInputFocused = true
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("AIChatViewShouldFocusInput"), object: nil)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let message = messageText
        messageText = ""
        aiVM.sendMessage(message)
    }
}

struct MessageBubble: View {
    let message: AIViewModel.AIMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .padding(12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)

                    if message.transactionCreated {
                        Text("✅ Транзакция создана")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(16)

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
    }
}

struct AnalysisView: View {
    @Binding var analysisText: String
    let onAnalyze: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if analysisText.isEmpty {
                    Button("Проанализировать расходы") {
                        onAnalyze()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                } else {
                    ScrollView {
                        Text(analysisText)
                            .padding()
                    }
                }
            }
            .navigationTitle("Анализ расходов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}
