import Foundation
import SwiftUI

enum AppTourStep: Int, CaseIterable, Identifiable {
    case todayExpense
    case createGoal
    case lastTransactions
    case operationsIncome
    case operationsWallets
    case operationsGoals
    case operationsExpenses
    case dragIncomeToWallet
    case dragWalletToGoalsExpenses
    case tourComplete

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .todayExpense:
            return "today_expense_title".localized
        case .createGoal:
            return "create_goal_title".localized
        case .lastTransactions:
            return "last_transactions_title".localized
        case .operationsIncome:
            return "operations_income_title".localized
        case .operationsWallets:
            return "operations_wallets_title".localized
        case .operationsGoals:
            return "operations_goals_title".localized
        case .operationsExpenses:
            return "operations_expenses_title".localized
        case .dragIncomeToWallet:
            return "drag_income_to_wallet_title".localized
        case .dragWalletToGoalsExpenses:
            return "drag_wallet_to_goals_expenses_title".localized
        case .tourComplete:
            let title = "tour_complete_title".localized
            print("🎯 AppTourManager возвращает title: '\(title)'")
            return title
        }
    }
    
    var description: String {
        switch self {
        case .todayExpense:
            return "today_expense_description".localized
        case .createGoal:
            return "create_goal_description".localized
        case .lastTransactions:
            return "last_transactions_description".localized
        case .operationsIncome:
            return "operations_income_description".localized
        case .operationsWallets:
            return "operations_wallets_description".localized
        case .operationsGoals:
            return "operations_goals_description".localized
        case .operationsExpenses:
            return "operations_expenses_description".localized
        case .dragIncomeToWallet:
            return "drag_income_to_wallet_description".localized
        case .dragWalletToGoalsExpenses:
            return "drag_wallet_to_goals_expenses_description".localized
        case .tourComplete:
            return "tour_complete_description".localized
        }
    }
}

class AppTourManager: ObservableObject {
    @Published var isTourActive: Bool = false
    @Published var currentStep: AppTourStep = .todayExpense
    @Published var isFirstLaunch: Bool = false

    func startTour() {
        isTourActive = true
        currentStep = .todayExpense
    }
    
    func nextStep() {
        print("🔄 nextStep() вызван для шага: \(currentStep)")
        if currentStep == .operationsGoals {
            currentStep = .operationsExpenses
            return
        }
        if currentStep == .dragIncomeToWallet {
            currentStep = .dragWalletToGoalsExpenses
            return
        }
        if currentStep == .dragWalletToGoalsExpenses {
            print("🔄 Переход от dragWalletToGoalsExpenses к tourComplete")
            currentStep = .tourComplete
            return
        }
        if let next = AppTourStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        } else {
            print("🔄 Завершение тура")
            isTourActive = false
        }
    }
    
    func prevStep() {
        if let prev = AppTourStep(rawValue: currentStep.rawValue - 1), prev.rawValue >= 0 {
            currentStep = prev
        }
    }
    
    func skipTour() {
        isTourActive = false
    }
    
    func restartTour() {
        isTourActive = true
        currentStep = .todayExpense
    }
} 