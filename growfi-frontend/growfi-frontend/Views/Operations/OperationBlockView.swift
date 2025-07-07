import SwiftUI

struct OperationBlockView: View {
    let title: String
    let icon: String
    let amount: String
    let color: Color
    let onAdd: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color)
                        .font(.title2)
                }
            }
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(amount)
                .font(.title3).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
} 
