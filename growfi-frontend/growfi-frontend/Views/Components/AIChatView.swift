import SwiftUI

struct AIChatView: View {
    let aiHints = [
        "Добавить расходы?",
        "Как быстрее накопить?",
        "Анализ расходов?",
        "Какой у меня баланс?",
        "Сколько я потратил на кофе?"
    ]
    @State private var searchText = ""
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(aiHints, id: \ .self) { hint in
                        Text(hint)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                            .onTapGesture {
                                searchText = hint
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            HStack(spacing: 8) {
                TextField("Задайте вопрос...", text: $searchText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 40, height: 40)
                        Image("plant_stage_0")
                            .resizable()
                            .frame(width: 22, height: 22)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
} 