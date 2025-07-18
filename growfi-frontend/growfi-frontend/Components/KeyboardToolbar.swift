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
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Модификатор для автоматического скрытия клавиатуры при тапе вне поля
struct HideKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    func hideKeyboardOnTap() -> some View {
        self.modifier(HideKeyboardOnTap())
    }
} 