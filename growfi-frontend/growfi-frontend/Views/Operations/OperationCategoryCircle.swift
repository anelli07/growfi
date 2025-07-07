import SwiftUI

struct OperationCategoryCircle: View {
    let icon: String
    let color: Color
    let title: String
    let amount: String

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
            Text(title)
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
