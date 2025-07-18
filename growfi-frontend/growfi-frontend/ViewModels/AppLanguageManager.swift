import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case ru = "ru"
    case en = "en"
    
    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        }
    }
}

class AppLanguageManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            String.clearLocalizationCache()
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    static let shared = AppLanguageManager()
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "AppLanguage"),
           let lang = AppLanguage(rawValue: saved) {
            currentLanguage = lang
        } else {
            currentLanguage = .ru
        }
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
} 