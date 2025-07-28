import SwiftUI
import UIKit

struct KeyboardToolbar: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(action: action) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
    }
}

extension View {
    func keyboardToolbar(action: @escaping () -> Void) -> some View {
        self.modifier(KeyboardToolbar(action: action))
    }
} 