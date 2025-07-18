import SwiftUI

extension View {
    func onLanguageChange() -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            // Принудительно обновляем View
        }
    }
} 