import Foundation
import UserNotifications
import SwiftUI

enum NotificationType: String, CaseIterable {
    case dailyReminder = "daily_reminder"
    case noActivity = "no_activity"
    case weeklySummary = "weekly_summary"
    
    var title: String {
        switch self {
        case .dailyReminder: return "GrowFi напоминает"
        case .noActivity: return "Скучаем по тебе"
        case .weeklySummary: return "Недельный отчет"
        }
    }
    
    var body: String {
        switch self {
        case .dailyReminder: return "Не забудь внести сегодняшние расходы — я жду 📒"
        case .noActivity: return "Я скучаю по твоим финансам… введи что-нибудь 😢"
        case .weeklySummary: return "Посмотри, как ты вырос за неделю 📊"
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
        
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о цели"
        let amount = Int(goal.planAmount ?? 0)
        content.body = "Пора пополнить '\(goal.name)' на \(amount)₸!"
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
}
