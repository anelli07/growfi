import SwiftUI

struct AIChatView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("ai_coming_soon".localized)
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}