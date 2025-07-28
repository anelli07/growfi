import Foundation
import UserNotifications
import SwiftUI

enum NotificationType: String, CaseIterable {
    case dailyReminder = "daily_reminder"
    case noActivity = "no_activity"
    case weeklySummary = "weekly_summary"
    case goalCompleted = "goal_completed"
    
    var title: String {
        switch self {
        case .dailyReminder: return "GrowFi напоминает"
        case .noActivity: return "Скучаем по тебе"
        case .weeklySummary: return "Недельный отчет"
        case .goalCompleted: return "🎉 Цель достигнута!"
        }
    }
    
    var body: String {
        switch self {
        case .dailyReminder: return "Не забудь внести сегодняшние расходы — я жду 📒"
        case .noActivity: return "Я скучаю по твоим финансам… введи что-нибудь 😢"
        case .weeklySummary: return "Посмотри, как ты вырос за неделю 📊"
        case .goalCompleted: return "Поздравляем! Ваша цель выполнена! 🎊"
        }
    }
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    var isSystemNotificationsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isSystemNotificationsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isSystemNotificationsEnabled") }
    }
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // --- Системные уведомления ---
    // 1. Daily reminder (если сегодня не было операций)
    func scheduleDailyReminderIfNeeded(transactions: [Transaction]) {
        guard isSystemNotificationsEnabled else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let hasToday = transactions.contains { calendar.isDate($0.date, inSameDayAs: today) }
        removeSystemNotification(type: .dailyReminder)
        guard !hasToday else { return }
        let content = UNMutableNotificationContent()
        content.title = NotificationType.dailyReminder.title
        content.body = NotificationType.dailyReminder.body
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 20:00
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: NotificationType.dailyReminder.rawValue, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    // 2. No activity (если не было операций 7 дней)
    func scheduleNoActivityReminder(transactions: [Transaction]) {
        guard isSystemNotificationsEnabled else { return }
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let hasRecent = transactions.contains { $0.date >= weekAgo }
        removeSystemNotification(type: .noActivity)
        guard !hasRecent else { return }
        let content = UNMutableNotificationContent()
        content.title = NotificationType.noActivity.title
        content.body = NotificationType.noActivity.body
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = 18 // 18:00
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: NotificationType.noActivity.rawValue, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    // 3. Weekly summary (если были операции за неделю)
    func scheduleWeeklySummaryReminder(transactions: [Transaction]) {
        guard isSystemNotificationsEnabled else { return }
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let hasWeekOps = transactions.contains { $0.date >= weekAgo }
        removeSystemNotification(type: .weeklySummary)
        guard hasWeekOps else { return }
        let content = UNMutableNotificationContent()
        content.title = NotificationType.weeklySummary.title
        content.body = NotificationType.weeklySummary.body
        content.sound = .default
        content.userInfo = ["openAnalytics": true]
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 15 // 15:00
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: NotificationType.weeklySummary.rawValue, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    // Удаление системных уведомлений
    func removeSystemNotification(type: NotificationType) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [type.rawValue])
    }
    
    // --- Персональные уведомления по целям ---
    func schedulePersonalGoalReminder(goal: Goal) {
        removePersonalGoalReminder(goalId: goal.id)
        guard let reminderPeriod = goal.reminderPeriod else { return } // если не выбрано напоминание — не планируем
        
        print("DEBUG: Проверяем уведомления для цели '\(goal.name)'")
        print("DEBUG: planPeriod = \(goal.planPeriod?.rawValue ?? "nil")")
        print("DEBUG: planAmount = \(goal.planAmount ?? -1)")
        print("DEBUG: createdAt = \(goal.createdAt?.description ?? "nil")")
        print("DEBUG: current_amount = \(goal.current_amount)")
        
        // Проверяем, пополнял ли пользователь цель в текущем периоде
        if hasGoalBeenFundedThisPeriod(goal: goal) {
            print("DEBUG: Цель '\(goal.name)' уже пополнена в текущем периоде, уведомление не отправляем")
            return
        }
        
        // Проверяем сумму для пополнения
        let amount = Int(goal.planAmount ?? 0)
        if amount <= 0 {
            print("DEBUG: Цель '\(goal.name)' - сумма пополнения 0 или отрицательная, уведомление не отправляем")
            return
        }
        
        // Проверяем, не пополнена ли уже цель на нужную сумму в этом периоде
        if hasGoalBeenFundedForAmount(goal: goal, requiredAmount: Double(amount)) {
            print("DEBUG: Цель '\(goal.name)' уже пополнена на нужную сумму в текущем периоде, уведомление не отправляем")
            return
        }
        
        // Рассчитываем оставшуюся сумму для пополнения
        let remainingAmount = calculateRemainingAmount(goal: goal)
        if remainingAmount <= 0 {
            print("DEBUG: Цель '\(goal.name)' - оставшаяся сумма \(remainingAmount)₸, уведомление не отправляем")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о цели"
        content.body = "Пора пополнить '\(goal.name)' на \(remainingAmount)₸!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        // Парсим время
        var selectedTime: Date? = nil
        if let timeString = goal.selectedTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            selectedTime = formatter.date(from: timeString)
        }
        
        switch reminderPeriod {
        case "week":
            dateComponents.weekday = goal.selectedWeekday ?? 2
            if let selectedTime = selectedTime {
                dateComponents.hour = Calendar.current.component(.hour, from: selectedTime)
                dateComponents.minute = Calendar.current.component(.minute, from: selectedTime)
            } else {
                dateComponents.hour = 9
                dateComponents.minute = 0
            }
        case "month":
            dateComponents.day = goal.selectedMonthDay ?? Calendar.current.component(.day, from: goal.createdAt ?? Date())
            if let selectedTime = selectedTime {
                dateComponents.hour = Calendar.current.component(.hour, from: selectedTime)
                dateComponents.minute = Calendar.current.component(.minute, from: selectedTime)
            } else {
                dateComponents.hour = 9
                dateComponents.minute = 0
            }
        default:
            return
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "goal_reminder_\(goal.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    func removePersonalGoalReminder(goalId: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["goal_reminder_\(goalId)"])
    }
    
    // Проверяем, пополнялась ли цель в текущем периоде
    private func hasGoalBeenFundedThisPeriod(goal: Goal) -> Bool {
        guard let planPeriod = goal.planPeriod,
              let planAmount = goal.planAmount,
              let createdAt = goal.createdAt else { 
            return false 
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Определяем текущий период на основе даты создания цели
        let currentPeriodNumber: Int
        if planPeriod == .week {
            let weeksSinceCreation = calendar.dateComponents([.weekOfYear], from: createdAt, to: now).weekOfYear ?? 0
            currentPeriodNumber = weeksSinceCreation
        } else {
            let monthsSinceCreation = calendar.dateComponents([.month], from: createdAt, to: now).month ?? 0
            currentPeriodNumber = monthsSinceCreation
        }
        
        // Получаем ключ для отслеживания последнего пополнения
        let lastFundedKey = "goal_last_funded_\(goal.id)"
        let periodKey = "goal_current_period_\(goal.id)"
        
        // Проверяем, тот же ли это период
        if let savedPeriod = UserDefaults.standard.object(forKey: periodKey) as? Int, savedPeriod == currentPeriodNumber {
            let hasBeenFunded = UserDefaults.standard.object(forKey: lastFundedKey) as? Date != nil
            print("DEBUG: Цель \(goal.name) - период \(currentPeriodNumber), пополнена в этом периоде: \(hasBeenFunded)")
            return hasBeenFunded
        }
        
        print("DEBUG: Цель \(goal.name) - период \(currentPeriodNumber), не пополнена в этом периоде")
        return false
    }
    
    // Отмечаем, что цель была пополнена
    func markGoalAsFunded(goalId: Int) {
        let lastFundedKey = "goal_last_funded_\(goalId)"
        UserDefaults.standard.set(Date(), forKey: lastFundedKey)
        print("DEBUG: Цель \(goalId) отмечена как пополненная")
    }
    
    // Отмечаем, что цель была пополнена на определенную сумму
    func markGoalAsFunded(goal: Goal, amount: Double) {
        guard let planPeriod = goal.planPeriod,
              let createdAt = goal.createdAt else {
            print("DEBUG: Не удалось получить данные цели \(goal.name) для отметки пополнения")
            return
        }
        
        let lastFundedKey = "goal_last_funded_\(goal.id)"
        let amountKey = "goal_funded_amount_\(goal.id)"
        let periodKey = "goal_current_period_\(goal.id)"
        
        let now = Date()
        UserDefaults.standard.set(now, forKey: lastFundedKey)
        
        // Определяем текущий период на основе даты создания цели
        let calendar = Calendar.current
        let currentPeriodNumber: Int
        if planPeriod == .week {
            let weeksSinceCreation = calendar.dateComponents([.weekOfYear], from: createdAt, to: now).weekOfYear ?? 0
            currentPeriodNumber = weeksSinceCreation
        } else {
            let monthsSinceCreation = calendar.dateComponents([.month], from: createdAt, to: now).month ?? 0
            currentPeriodNumber = monthsSinceCreation
        }
        
        // Проверяем, тот же ли это период
        if let savedPeriod = UserDefaults.standard.object(forKey: periodKey) as? Int, savedPeriod == currentPeriodNumber {
            // Добавляем к существующей сумме
            let currentAmount = UserDefaults.standard.double(forKey: amountKey)
            UserDefaults.standard.set(currentAmount + amount, forKey: amountKey)
        } else {
            // Новый период, начинаем с нуля
            UserDefaults.standard.set(amount, forKey: amountKey)
            UserDefaults.standard.set(currentPeriodNumber, forKey: periodKey)
        }
        
        print("DEBUG: Цель \(goal.name) пополнена на \(amount)₸ в периоде \(currentPeriodNumber)")
    }
    

    
    // Проверяем, пополнена ли цель на нужную сумму в текущем периоде
    private func hasGoalBeenFundedForAmount(goal: Goal, requiredAmount: Double) -> Bool {
        guard let planPeriod = goal.planPeriod,
              let planAmount = goal.planAmount,
              let createdAt = goal.createdAt else { 
            return false 
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Определяем текущий период на основе даты создания цели
        let currentPeriodNumber: Int
        if planPeriod == .week {
            let weeksSinceCreation = calendar.dateComponents([.weekOfYear], from: createdAt, to: now).weekOfYear ?? 0
            currentPeriodNumber = weeksSinceCreation
        } else {
            let monthsSinceCreation = calendar.dateComponents([.month], from: createdAt, to: now).month ?? 0
            currentPeriodNumber = monthsSinceCreation
        }
        
        let amountKey = "goal_funded_amount_\(goal.id)"
        let periodKey = "goal_current_period_\(goal.id)"
        
        // Проверяем, тот же ли это период
        if let savedPeriod = UserDefaults.standard.object(forKey: periodKey) as? Int, savedPeriod == currentPeriodNumber {
            let fundedAmount = UserDefaults.standard.double(forKey: amountKey)
            print("DEBUG: Цель \(goal.name) - период \(currentPeriodNumber), пополнено \(fundedAmount)₸, нужно \(requiredAmount)₸")
            return fundedAmount >= requiredAmount
        }
        
        return false
    }
    
    // Рассчитываем оставшуюся сумму для пополнения в текущем периоде
    private func calculateRemainingAmount(goal: Goal) -> Int {
        guard let planPeriod = goal.planPeriod,
              let planAmount = goal.planAmount,
              let createdAt = goal.createdAt else { 
            return 0 
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Определяем текущий период на основе даты создания цели
        let currentPeriodNumber: Int
        if planPeriod == .week {
            let weeksSinceCreation = calendar.dateComponents([.weekOfYear], from: createdAt, to: now).weekOfYear ?? 0
            currentPeriodNumber = weeksSinceCreation
        } else {
            let monthsSinceCreation = calendar.dateComponents([.month], from: createdAt, to: now).month ?? 0
            currentPeriodNumber = monthsSinceCreation
        }
        
        print("DEBUG: Цель \(goal.name) - текущий период \(currentPeriodNumber)")
        
        // Рассчитываем, сколько должно быть накоплено к текущему периоду
        let expectedAmount = Double(currentPeriodNumber + 1) * planAmount
        print("DEBUG: Цель \(goal.name) - ожидаемая сумма к периоду \(currentPeriodNumber + 1): \(expectedAmount)₸")
        
        // Рассчитываем, сколько уже накоплено
        let currentAmount = goal.current_amount
        print("DEBUG: Цель \(goal.name) - текущая сумма: \(currentAmount)₸")
        
        // Рассчитываем оставшуюся сумму для текущего периода
        let remainingAmount = max(0, expectedAmount - currentAmount)
        print("DEBUG: Цель \(goal.name) - оставшаяся сумма: \(remainingAmount)₸")
        
        return Int(remainingAmount)
    }
    
    // --- Проверка завершения целей ---
    func checkGoalCompletion(goals: [Goal]) {
        for goal in goals {
            // Проверяем, достигнута ли цель
            if goal.current_amount >= goal.target_amount {
                // Проверяем, не отправляли ли мы уже поздравление для этой цели
                let completionKey = "goal_completed_\(goal.id)"
                let hasBeenNotified = UserDefaults.standard.bool(forKey: completionKey)
                
                if !hasBeenNotified {
                    // Отправляем поздравление
                    sendGoalCompletionNotification(goal: goal)
                    // Отмечаем, что поздравление отправлено
                    UserDefaults.standard.set(true, forKey: completionKey)
                    // Останавливаем напоминания для этой цели
                    removePersonalGoalReminder(goalId: goal.id)
                }
            } else {
                // Если цель не достигнута, сбрасываем флаг уведомления
                let completionKey = "goal_completed_\(goal.id)"
                UserDefaults.standard.set(false, forKey: completionKey)
            }
        }
    }
    
    // --- Отправка поздравления о завершении цели ---
    private func sendGoalCompletionNotification(goal: Goal) {
        guard isSystemNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Цель '\(goal.name)' достигнута!"
        content.body = "Поздравляем! Вы накопили \(Int(goal.target_amount))₸! 🎊"
        content.sound = .default
        content.userInfo = [
            "goalId": goal.id,
            "goalName": goal.name,
            "action": "goal_completed"
        ]
        
        // Отправляем уведомление немедленно
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "goal_completion_\(goal.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling goal completion notification: \(error)")
            } else {
                print("Goal completion notification scheduled for goal: \(goal.name)")
            }
        }
        
        // Показываем запрос на оценку при достижении цели (если еще не оценили)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if AppRatingManager.shared.shouldShowRatingRequest() {
                AppRatingManager.shared.requestAppRating()
            }
        }
    }
    
    // --- Сброс флага завершения цели (при удалении или сбросе) ---
    func resetGoalCompletionFlag(goalId: Int) {
        let completionKey = "goal_completed_\(goalId)"
        UserDefaults.standard.removeObject(forKey: completionKey)
    }
}
