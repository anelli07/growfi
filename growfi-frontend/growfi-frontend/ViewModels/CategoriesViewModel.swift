import Foundation
import Combine

class CategoriesViewModel: ObservableObject {
    @Published var incomeCategories: [Category] = []
    @Published var expenseCategories: [Category] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    var token: String? {
        UserDefaults.standard.string(forKey: "access_token")
    }

    func fetchCategories() {
        guard let token = token else { return }
        isLoading = true
        ApiService.shared.fetchCategories(token: token) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let categories):
                    self?.incomeCategories = categories.filter { $0.type == "INCOME" }
                    self?.expenseCategories = categories.filter { $0.type == "EXPENSE" }
                case .failure(let err):
                    self?.error = err.localizedDescription
                }
            }
        }
    }
} 