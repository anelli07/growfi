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
            return "Расходы за сегодня"
        case .createGoal:
            return "Создать цель"
        case .lastTransactions:
            return "Последние транзакции"
        case .operationsIncome:
            return "Доходы"
        case .operationsWallets:
            return "Кошельки"
        case .operationsGoals:
            return "Цели"
        case .operationsExpenses:
            return "Расходы"
        case .dragIncomeToWallet:
            return "Перетащите доход на кошелёк"
        case .dragWalletToGoalsExpenses:
            return "Переводите деньги с кошелька"
        case .tourComplete:
            let title = "Отлично! Вы готовы"
            print("🎯 AppTourManager возвращает title: '\(title)'")
            return title
        }
    }
    
    var description: String {
        switch self {
        case .todayExpense:
            return "Здесь отображаются все ваши траты за текущий день — удобно для ежедневного контроля бюджета."
        case .createGoal:
            return "Создайте цель, чтобы начать копить деньги на важные покупки или мечты."
        case .lastTransactions:
            return "Здесь будут показаны ваши последние действия — доходы, расходы и переводы."
        case .operationsIncome:
            return "Здесь создаются источники доходов — зарплата, стипендия и т.д. Они нужны, чтобы указывать, откуда поступили деньги."
        case .operationsWallets:
            return "Добавляйте свои карты и наличные. Кошельки создаются вручную для учёта, где хранятся деньги."
        case .operationsGoals:
            return "Создавайте финансовые цели и переводите на них деньги с кошельков. Удобно для накоплений."
        case .operationsExpenses:
            return "Создайте категории трат. Перетаскивайте на них деньги из кошельков для учёта расходов."
        case .dragIncomeToWallet:
            return "Чтобы пополнить кошелёк, перетащите доход на нужный кошелёк."
        case .dragWalletToGoalsExpenses:
            return "Переводите деньги с кошелька на цели для накоплений или на расходы для учёта трат."
        case .tourComplete:
            return "Теперь вы знаете все основные функции приложения. Начните управлять своими финансами!"
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