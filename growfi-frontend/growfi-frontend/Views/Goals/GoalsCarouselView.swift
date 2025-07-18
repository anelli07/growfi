import SwiftUI

struct GoalsCarouselView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @EnvironmentObject var walletsVM: WalletsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @Binding var selectedTab: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showAIChat = false
    @State private var showCreateGoalSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                GreetingView(userName: viewModel.userName)
                                .padding(.top, 12) // чёткий отступ сверху
                                .padding(.bottom, 10) // ≈ 0.5 см
                TodayExpenseView(todayExpense: viewModel.todayExpense)
                    .padding(.top, 6) // немного воздуха между заголовками
                
                if viewModel.goals.isEmpty {
                    EmptyGoalView(showCreateGoalSheet: $showCreateGoalSheet) { name, sum, icon, color, currency in
                        viewModel.createGoal(name: name, targetAmount: sum, currency: currency.isEmpty ? "₸" : currency, icon: icon.isEmpty ? "leaf.circle.fill" : icon, color: color.isEmpty ? "#00FF00" : color)
                        showCreateGoalSheet = false
                    }
                } else if viewModel.goals.count == 1, let goal = viewModel.goals.first {
                    SingleGoalView(goal: goal)
                } else {

                    CarouselView(items: viewModel.goals, selectedIndex: $viewModel.selectedGoalIndex) { goal, isActive in
                        VStack(spacing: 2) {
                            Image("plant_stage_\(goal.growthStage)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: isActive ? 180 : 120, height: isActive ? 180 : 120)
                                .shadow(color: .black.opacity(isActive ? 0.15 : 0), radius: 8, x: 0, y: 4)
                            Text(goal.name.localizedIfDefault)
                                .font(isActive ? .headline : .subheadline)
                                .foregroundColor(isActive ? .primary : .gray)
                                .lineLimit(1)
                                .frame(width: isActive ? 120 : 80)
                            Text("\(Int(goal.current_amount)) / \(Int(goal.target_amount))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            ProgressView(value: goal.current_amount, total: goal.target_amount)
                                .accentColor(Color.green)
                                .frame(width: isActive ? 120 : 80)
                                .padding(.bottom, 0)
                        }
                    }
                    .frame(height: 260)
                    .padding(.top, 12)

                }
                
                Spacer(minLength: 4)
                
                if viewModel.goals.count > 1,
                   let goal = viewModel.goals[safe: viewModel.selectedGoalIndex] {
                    GoalDetailsView(goal: goal)
                }
                
                LastTransactionsView(
                    onShowHistory: { selectedTab = 0 },
                    todayTransactions: viewModel.todayTransactions
                )
                .id(AppLanguageManager.shared.currentLanguage)
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 16)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                
                // SearchBar(
                //     placeholder: "Добавить расходы? Как быстрее накопить? Анализ расходов?",
                //     text: .constant("")
                // )
                // .onTapGesture { showAIChat = true }
                // .padding(.horizontal)
                // .padding(.bottom, 32)
                // .frame(height: 44)
                // .sheet(isPresented: $showAIChat) {
                //     AIChatView()
                // }
            }
        }
        .onAppear {
            viewModel.historyVM = historyVM
        }
        .onLanguageChange()
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            // Принудительно обновляем View при смене языка
        }
    }
}

// --- Компоненты ---
struct GreetingView: View {
    let userName: String
    var body: some View {
        HStack {
            Text(String(format: "GreetingUser".localized, userName))
                .font(.title2).bold()
            Spacer()
        }
        .padding(.horizontal)
        .onLanguageChange()
    }
}

struct TodayExpenseView: View {
    let todayExpense: Double
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.red)
            Text("TodayExpense".localized)
                .font(.subheadline)
            Text("\(Int(todayExpense)) ₸")
                .foregroundColor(.red)
                .font(.subheadline).bold()
            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .padding(.horizontal)
        .onLanguageChange()
    }
}

struct EmptyGoalView: View {
    @Binding var showCreateGoalSheet: Bool
    var onCreate: (String, Double, String, String, String) -> Void
    var body: some View {
        VStack(spacing: 10) {
            Image("plant_stage_0")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
            Button(action: { showCreateGoalSheet = true }) {
                Text("CreateGoal".localized)
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
        .padding(.top, 8)
        .sheet(isPresented: $showCreateGoalSheet) {
            CreateItemSheet(type: .goal) { name, sum, icon, color, currency in
                onCreate(name, sum, "", "", "")
            }
        }
        .onLanguageChange()
    }
}

struct SingleGoalView: View {
    let goal: Goal
    @State private var showOperations = false
    var body: some View {
        VStack(spacing: 4) {
            Image("plant_stage_\(goal.growthStage)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
            Text(goal.name.localizedIfDefault)
                .font(.subheadline)
            Text("\(Int(goal.current_amount)) / \(Int(goal.target_amount))")
                .font(.subheadline)
                .foregroundColor(.gray)
            ProgressView(value: goal.current_amount, total: goal.target_amount)
                .accentColor(Color.green)
                .frame(width: 180)
                .padding(.bottom, 4)
            Button(action: {
                showOperations = true
            }) {
                Text("ReplenishGoal".localized)
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showOperations) {
                OperationsView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .onLanguageChange()
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
//            Text("\(Int(goal.current_amount)) / \(Int(goal.target_amount))")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//            ProgressView(value: goal.current_amount, total: goal.target_amount)
//                        .accentColor(Color.green)
//                .frame(height: 4)
//                        .padding(.horizontal, 24)
            Button(action: {
                // TODO: Sheet для пополнения цели
            }) {
                Text("ReplenishGoal".localized)
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .frame(height: 44)
        }
        .onLanguageChange()
    }
}

struct LastTransactionsView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    var onShowHistory: () -> Void = {}
    var todayTransactions: [Transaction] = []
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("LastTransactions".localized)
                    .font(.headline)
                Spacer()
                Button(action: { onShowHistory() }) {
                    HStack(spacing: 4) {
                        Text("Details".localized)
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
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 6) {
                    ForEach(todayTransactions) { tx in
                        TransactionCell(transaction: tx)
                    }
                }
            }
            .frame(height: todayTransactions.isEmpty ? 44 : 3 * 56)
        }
        .padding(8)
        .background(Color(.systemGray5))
        .onLanguageChange()
    }
}

// --- Новый CarouselView ---
struct CarouselView<Content: View, T: Identifiable>: View {
    let items: [T]
    @Binding var selectedIndex: Int
    let content: (T, Bool) -> Content

    @State private var dragOffset: CGFloat = 0

    private let spacingFactor: CGFloat = 0.28
    private let minScale: CGFloat = 0.7
    private let minOpacity: CGFloat = 0.4
    private let maxBlur: CGFloat = 4.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(items.indices, id: \ .self) { idx in
                    let delta = circularDelta(idx, selectedIndex, items.count)
                    let isActive = idx == selectedIndex

                    let baseX = CGFloat(delta) * geo.size.width * spacingFactor
                    let xOffset = isActive ? baseX + dragOffset : baseX
                    let scale = isActive ? 1.0 : minScale
                    let opacity = isActive ? 1.0 : minOpacity
                    let z = isActive ? 10.0 : Double(10 - abs(delta))
                    let blur = abs(delta) > 1 ? maxBlur : 0

                    content(items[idx], isActive)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .blur(radius: blur)
                        .offset(x: xOffset)
                        .zIndex(z)
                        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedIndex)
                        .onTapGesture {
                            withAnimation { selectedIndex = idx }
                        }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = geo.size.width * 0.15
                        if dragOffset < -threshold {
                            selectedIndex = (selectedIndex + 1) % items.count
                        } else if dragOffset > threshold {
                            selectedIndex = (selectedIndex - 1 + items.count) % items.count
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
            )
        }
    }

    private func circularDelta(_ idx: Int, _ selected: Int, _ count: Int) -> Int {
        let direct = idx - selected
        if direct > count / 2 {
            return direct - count
        } else if direct < -count / 2 {
            return direct + count
        } else {
            return direct
        }
    }
}
