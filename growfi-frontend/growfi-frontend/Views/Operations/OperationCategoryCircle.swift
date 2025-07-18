import SwiftUI

struct OperationCategoryCircle: View {
    let icon: String
    let color: Color
    let title: String
    let amount: String
    var onDrag: (() -> NSItemProvider)? = nil
    var onDrop: (([NSItemProvider]) -> Bool)? = nil

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .medium))
            }
            .contentShape(Circle())
            .ifLet(onDrag) { view, onDrag in
                view.onDrag(onDrag)
            }
            .ifLet(onDrop) { view, onDrop in
                view.onDrop(of: ["public.text"], isTargeted: nil, perform: onDrop)
            }
            Text(title.localizedIfDefault)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 60)
            if !amount.isEmpty {
                Text(amount)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 60)
            }
        }
        .frame(width: 56)
    }
}

// SwiftUI View extension for conditional modifier
extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}
