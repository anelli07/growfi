import SwiftUI

struct AIChatView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("ИИ-помощник скоро будет доступен 🚀")
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}