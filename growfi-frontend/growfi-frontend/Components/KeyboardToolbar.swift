import SwiftUI
import UIKit

struct KeyboardToolbar: ViewModifier {
    let title: String
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(title) {
                        action()
                    }
                    .foregroundColor(.blue)
                }
            }
    }
}

extension View {
    func keyboardToolbar(title: String = "Готово", action: @escaping () -> Void) -> some View {
        self.modifier(KeyboardToolbar(title: title, action: action))
    }
} 