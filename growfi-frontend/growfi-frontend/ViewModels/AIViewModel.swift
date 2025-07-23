import Foundation
import Combine

class AIViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }
    
    struct AIMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp: Date
        let response: String?
        let transactionCreated: Bool
    }
    
    func sendMessage(_ text: String) {
        guard let token = token else {
            error = "Не авторизован"
            return
        }
        
        // Добавляем сообщение пользователя
        let userMessage = AIMessage(text: text, isUser: true, timestamp: Date(), response: nil, transactionCreated: false)
        messages.append(userMessage)
        
        isLoading = true
        error = nil
        
        ApiService.shared.processAIMessage(message: text, token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    let aiResponse = response["response"] as? String ?? "Ошибка обработки"
                    let transactionCreated = response["type"] as? String == "transaction"
                    
                    let aiMessage = AIMessage(
                        text: aiResponse,
                        isUser: false,
                        timestamp: Date(),
                        response: aiResponse,
                        transactionCreated: transactionCreated
                    )
                    self?.messages.append(aiMessage)
                    
                case .failure(let err):
                    self?.error = err.localizedDescription
                    
                    let errorMessage = AIMessage(
                        text: "Ошибка: \(err.localizedDescription)",
                        isUser: false,
                        timestamp: Date(),
                        response: nil,
                        transactionCreated: false
                    )
                    self?.messages.append(errorMessage)
                }
            }
        }
    }
    
    func analyzeExpenses(period: String = "month", completion: @escaping (String) -> Void) {
        guard let token = token else {
            completion("Ошибка авторизации")
            return
        }
        
        isLoading = true
        
        ApiService.shared.analyzeExpenses(token: token, period: period) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    let analysis = response["analysis"] as? String ?? "Не удалось проанализировать"
                    completion(analysis)
                    
                case .failure(let err):
                    completion("Ошибка анализа: \(err.localizedDescription)")
                }
            }
        }
    }
    
    func clearMessages() {
        messages.removeAll()
    }
} 