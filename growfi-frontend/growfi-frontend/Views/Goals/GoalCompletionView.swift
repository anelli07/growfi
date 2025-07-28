import SwiftUI

struct GoalCompletionView: View {
    let goal: Goal
    @ObservedObject var goalsVM: GoalsViewModel
    @State private var showConfetti = false
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Полупрозрачный фон
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Компактное модальное окно
            VStack(spacing: 20) {
                // Иконка цели с анимацией
                ZStack {
                    Circle()
                        .fill(Color(hex: goal.color))
                        .frame(width: 80, height: 80)
                        .scaleEffect(showConfetti ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showConfetti)
                    
                    Image(systemName: goal.icon)
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }
                
                // Заголовок поздравления
                VStack(spacing: 8) {
                    Text("🎉 Поздравляем!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Цель '\(goal.name)' достигнута!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Компактная информация о цели
                VStack(spacing: 8) {
                    HStack {
                        Text("Накоплено:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(goal.current_amount)) \(goal.currency)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: goal.color))
                    }
                    
                    HStack {
                        Text("Время:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(daysBetween(from: goal.createdAt ?? Date(), to: Date())) дней")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .onAppear {
                        print("DEBUG: GoalCompletionView - goal.createdAt: \(goal.createdAt?.description ?? "nil")")
                        print("DEBUG: GoalCompletionView - days calculated: \(daysBetween(from: goal.createdAt ?? Date(), to: Date()))")
                    }
                }
                .padding(.horizontal)
                
                // Компактные кнопки действий
                HStack(spacing: 12) {
                    Button(action: {
                        showConfetti = false
                        onDismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Оставить")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        showConfetti = false
                        // Проверяем, что цель существует перед удалением
                        if goal.id > 0 {
                            goalsVM.deleteGoal(goalId: goal.id)
                        }
                        onDismiss()
                    }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                            Text("Удалить")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
            
            // Конфетти (анимация)
            if showConfetti {
                ConfettiView(showConfetti: $showConfetti)
            }
        }
        .onAppear {
            showConfetti = true
        }
    }
    
    private func daysBetween(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        let days = components.day ?? 0
        
        // Если цель создана сегодня, показываем 1 день
        if days == 0 && calendar.isDateInToday(startDate) {
            return 1
        }
        
        return max(1, days) // Минимум 1 день
    }
}

// Анимация салюта
struct ConfettiView: View {
    @Binding var showConfetti: Bool
    @State private var particles: [FireworkParticle] = []
    @State private var animationPhase: Int = 0
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            createFireworks()
        }
    }
    
    private func createFireworks() {
        // Создаем много салютов со всех сторон экрана
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Салюты по периметру экрана
        let fireworkPositions = [
            // Верхняя часть
            CGPoint(x: screenWidth * 0.1, y: screenHeight * 0.1),
            CGPoint(x: screenWidth * 0.3, y: screenHeight * 0.15),
            CGPoint(x: screenWidth * 0.5, y: screenHeight * 0.1),
            CGPoint(x: screenWidth * 0.7, y: screenHeight * 0.15),
            CGPoint(x: screenWidth * 0.9, y: screenHeight * 0.1),
            
            // Нижняя часть
            CGPoint(x: screenWidth * 0.1, y: screenHeight * 0.9),
            CGPoint(x: screenWidth * 0.3, y: screenHeight * 0.85),
            CGPoint(x: screenWidth * 0.5, y: screenHeight * 0.9),
            CGPoint(x: screenWidth * 0.7, y: screenHeight * 0.85),
            CGPoint(x: screenWidth * 0.9, y: screenHeight * 0.9),
            
            // Левая часть
            CGPoint(x: screenWidth * 0.1, y: screenHeight * 0.3),
            CGPoint(x: screenWidth * 0.1, y: screenHeight * 0.5),
            CGPoint(x: screenWidth * 0.1, y: screenHeight * 0.7),
            
            // Правая часть
            CGPoint(x: screenWidth * 0.9, y: screenHeight * 0.3),
            CGPoint(x: screenWidth * 0.9, y: screenHeight * 0.5),
            CGPoint(x: screenWidth * 0.9, y: screenHeight * 0.7),
            
            // Центр
            CGPoint(x: screenWidth * 0.5, y: screenHeight * 0.5)
        ]
        
        // Создаем все салюты одновременно
        for position in fireworkPositions {
            createFirework(at: position)
        }
        
        // Повторяем салют 2 раза с интервалом
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if showConfetti {
                particles.removeAll()
                createFireworks()
            }
        }
        
        // Останавливаем салют через 8 секунд
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            showConfetti = false
        }
    }
    
    private func createFirework(at position: CGPoint) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan, .mint, .indigo, .teal, .brown, .gray]
        
        // Создаем 20-30 частиц для каждого салюта
        for _ in 0..<Int.random(in: 20...30) {
            let angle = Double.random(in: 0...2 * .pi)
            let distance = Double.random(in: 50...150)
            let endX = position.x + CGFloat(cos(angle) * distance)
            let endY = position.y + CGFloat(sin(angle) * distance)
            
            let particle = FireworkParticle(
                position: position,
                endPosition: CGPoint(x: endX, y: endY),
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 3...8),
                opacity: 1.0,
                scale: 0.1
            )
            particles.append(particle)
        }
        
        // Анимация взрыва
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 2.0)) {
                for i in particles.indices {
                    if particles[i].position == position {
                        particles[i].position = particles[i].endPosition
                        particles[i].opacity = 0
                        particles[i].scale = 1.0
                    }
                }
            }
        }
    }
}

struct FireworkParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let endPosition: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var scale: CGFloat
}



#Preview {
    GoalCompletionView(
        goal: Goal(
            id: 1,
            name: "Машина",
            target_amount: 2000000,
            current_amount: 2000000,
            user_id: 1,
            icon: "car.fill",
            color: "#34c759",
            currency: "₸",
            planPeriod: .month,
            planAmount: 100000,
            createdAt: Date().addingTimeInterval(-30*24*60*60), // 30 дней назад
            reminderPeriod: "month",
            selectedWeekday: nil,
            selectedMonthDay: 1,
            selectedTime: "9:00 AM"
        ),
        goalsVM: GoalsViewModel(),
        onDismiss: {}
    )
} 