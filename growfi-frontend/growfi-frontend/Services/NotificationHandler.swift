import Foundation
import UserNotifications

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()
    
    var onGoalCompleted: ((Goal) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // Обработка уведомлений когда приложение открыто
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Показываем уведомление даже когда приложение открыто
        completionHandler([.banner, .sound, .badge])
        
        // Обрабатываем уведомление о завершении цели
        let userInfo = notification.request.content.userInfo
        if let action = userInfo["action"] as? String,
           action == "goal_completed" {
            handleGoalCompletion(userInfo: userInfo)
        }
    }
    
    // Обработка нажатия на уведомление
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Обрабатываем уведомление о завершении цели
        if let action = userInfo["action"] as? String,
           action == "goal_completed" {
            handleGoalCompletion(userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleGoalCompletion(userInfo: [AnyHashable: Any]) {
        // Создаем объект Goal из userInfo
        if let goalId = userInfo["goalId"] as? Int,
           let goalName = userInfo["goalName"] as? String {
            
            // Загружаем реальную цель из базы данных
            if let token = UserDefaults.standard.string(forKey: "access_token") {
                ApiService.shared.fetchGoals(token: token) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let goals):
                            if let realGoal = goals.first(where: { $0.id == goalId }) {
                                // Вызываем callback с реальной целью
                                self.onGoalCompleted?(realGoal)
                            } else {
                                // Если цель не найдена, создаем минимальный объект
                                let goal = Goal(
                                    id: goalId,
                                    name: goalName,
                                    target_amount: 0,
                                    current_amount: 0,
                                    user_id: 0,
                                    icon: "star.fill",
                                    color: "#34c759",
                                    currency: "₸",
                                    planPeriod: nil,
                                    planAmount: nil,
                                    createdAt: Date(),
                                    reminderPeriod: nil,
                                    selectedWeekday: nil,
                                    selectedMonthDay: nil,
                                    selectedTime: nil
                                )
                                self.onGoalCompleted?(goal)
                            }
                        case .failure:
                            // В случае ошибки создаем минимальный объект
                            let goal = Goal(
                                id: goalId,
                                name: goalName,
                                target_amount: 0,
                                current_amount: 0,
                                user_id: 0,
                                icon: "star.fill",
                                color: "#34c759",
                                currency: "₸",
                                planPeriod: nil,
                                planAmount: nil,
                                createdAt: Date(),
                                reminderPeriod: nil,
                                selectedWeekday: nil,
                                selectedMonthDay: nil,
                                selectedTime: nil
                            )
                            self.onGoalCompleted?(goal)
                        }
                    }
                }
            }
        }
    }
} 