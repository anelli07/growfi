import SwiftUI

struct GoalsCarouselView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showAIChat = false
    @State private var showCreateGoalSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 6)
            GreetingView(userName: viewModel.userName)
            Spacer(minLength: 4)
            TodayExpenseView(todayExpense: viewModel.todayExpense)
            Spacer(minLength: 8)

            if viewModel.goals.isEmpty {
                EmptyGoalView(showCreateGoalSheet: $showCreateGoalSheet) {
                    viewModel.addGoal(name: $0, amount: $1)
                    showCreateGoalSheet = false
                }
            } else if viewModel.goals.count == 1, let goal = viewModel.goals.first {
                SingleGoalView(goal: goal)
            } else {
                GoalsCarousel(
                    goals: viewModel.goals,
                    selectedGoalIndex: $viewModel.selectedGoalIndex,
                    dragOffset: $dragOffset,
                    isDragging: $isDragging
                )
            }

            Spacer(minLength: 8)

            if viewModel.goals.count > 1,
               let goal = viewModel.goals[safe: viewModel.selectedGoalIndex] {
                GoalDetailsView(goal: goal)
            }

            Spacer(minLength: 12)

            LastTransactionsView(transactions: viewModel.todayTransactions)

            Spacer(minLength: 16)

            // Поисковик ИИ — внизу, с отступом для tabbar
            SearchBar(
                placeholder: "Добавить расходы? Как быстрее накопить? Анализ расходов?",
                text: .constant("")
            )
            .onTapGesture { showAIChat = true }
            .padding(.horizontal)
            .padding(.bottom, 36)
            .frame(height: 44)
            .sheet(isPresented: $showAIChat) {
                AIChatView()
            }
        }
    }
}

// --- Компоненты ---
struct GreetingView: View {
    let userName: String
    var body: some View {
        HStack {
            Text("Привет, \(userName)👋")
                .font(.title2).bold()
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct TodayExpenseView: View {
    let todayExpense: Double
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.red)
            Text("Расходы за сегодня:")
                .font(.subheadline)
            Text("\(Int(todayExpense)) т")
                .foregroundColor(.red)
                .font(.subheadline).bold()
            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .padding(.horizontal)
    }
}

struct EmptyGoalView: View {
    @Binding var showCreateGoalSheet: Bool
    var onCreate: (String, Double) -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image("plant_stage_0")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
            Button(action: { showCreateGoalSheet = true }) {
                Text("Создать цель")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 1)
                    )
            }
            VStack(spacing: 4) {
                Text("0 / 0")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                ProgressView(value: 0, total: 1)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(width: 180)
            }
        }
        .padding(.top, 20)
        .sheet(isPresented: $showCreateGoalSheet) {
            CreateItemSheet(type: .goal) { name, sum in
                onCreate(name, sum)
            }
        }
    }
}

struct SingleGoalView: View {
    let goal: Goal
    var body: some View {
        VStack(spacing: 10) {
            Image("plant_stage_\(goal.growthStage)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
            Text(goal.name)
                .font(.subheadline)
            Text("\(Int(goal.current_amount)) / \(Int(goal.target_amount))")
                .font(.subheadline)
                .foregroundColor(.gray)
            ProgressView(value: goal.current_amount, total: goal.target_amount)
                .accentColor(Color.green)
                .frame(width: 180)
                .padding(.bottom, 4)
            Button(action: {
                // TODO: Sheet для пополнения цели
            }) {
                Text("Пополнить цель")
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}

struct GoalsCarousel: View {
    let goals: [Goal]
    @Binding var selectedGoalIndex: Int
    @Binding var dragOffset: CGFloat
    @Binding var isDragging: Bool
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let itemWidth: CGFloat = width * 0.6
            let spacing: CGFloat = goals.count <= 2 ? -itemWidth * 0.35 : -itemWidth * 0.3
            let goalsCount = goals.count
            let centerX = width / 2
            let itemSpacing = itemWidth + spacing
            let centerOffset = centerX - itemWidth / 2
            let selectedIndexOffset = CGFloat(selectedGoalIndex) * itemSpacing
            let offset = -selectedIndexOffset + dragOffset + centerOffset
            let visibleIndices: [Int] = {
                let center = selectedGoalIndex
                if goalsCount == 2 {
                    return [center, (center + 1) % goalsCount]
                } else {
                    return [
                        (center - 1 + goalsCount) % goalsCount,
                        center,
                        (center + 1) % goalsCount
                    ]
                }
            }()
            HStack(spacing: spacing) {
                ForEach(visibleIndices, id: \ .self) { index in
                    let goal = goals[index]
                    let isSelected = index == selectedGoalIndex
                    let position = index - selectedGoalIndex
                    GoalCardView(goal: goal, isSelected: isSelected)
                        .frame(width: itemWidth)
                        .rotation3DEffect(
                            .degrees(Double(position) * 30),
                            axis: (x: 0, y: -1, z: 0),
                            perspective: 0.8
                        )
                        .scaleEffect(isSelected ? 1.0 : 0.85)
                        .opacity(isSelected ? 1.0 : 0.4)
                        .zIndex(isSelected ? 1 : 0)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedGoalIndex = index
                            }
                        }
                }
            }
            .offset(x: offset + centerX - itemWidth / 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                        isDragging = true
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        withAnimation(.spring()) {
                            if value.translation.width < -threshold {
                                selectedGoalIndex = (selectedGoalIndex + 1) % goalsCount
                            } else if value.translation.width > threshold {
                                selectedGoalIndex = (selectedGoalIndex - 1 + goalsCount) % goalsCount
                            }
                        }
                        dragOffset = 0
                        isDragging = false
                    }
            )
        }
        .frame(height: 180)
    }
}

struct GoalDetailsView: View {
    let goal: Goal
    var body: some View {
        VStack(spacing: 10) {
            Text("\(Int(goal.current_amount)) / \(Int(goal.target_amount))")
                .font(.subheadline)
                .foregroundColor(.gray)
            ProgressView(value: goal.current_amount, total: goal.target_amount)
                .accentColor(Color.green)
                .frame(height: 4)
                .padding(.horizontal, 24)
            Button(action: {
                // TODO: Sheet для пополнения цели
            }) {
                Text("Пополнить цель")
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .frame(height: 44)
        }
    }
}

struct LastTransactionsView: View {
    let transactions: [Transaction]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Последние транзакции")
                    .font(.headline)
                Spacer()
                Button(action: {
                    // TODO: переход в историю
                }) {
                    HStack(spacing: 4) {
                        Text("Подробнее")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
                }
            }
            .padding(.bottom, 2)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(transactions.prefix(3)) { tx in
                        HStack {
                            Text(tx.category)
                                .font(.subheadline)
                            Spacer()
                            Text("\(tx.type == .income ? "+" : "-")\(Int(abs(tx.amount))) \(tx.wallet)")
                                .foregroundColor(tx.type == .income ? .green : .red)
                                .font(.subheadline)
                        }
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .frame(height: min(CGFloat(transactions.count), 3) * 44)
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(14)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
