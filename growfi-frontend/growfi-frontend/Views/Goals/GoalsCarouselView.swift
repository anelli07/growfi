import SwiftUI

struct ArrowAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: isAnimating ? 20 : -20)
            .opacity(isAnimating ? 1 : 0.3)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct DiagonalArrowAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: isAnimating ? 15 : -15, y: isAnimating ? 15 : -15)
            .opacity(isAnimating ? 1 : 0.3)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct CardToExpenseArrowAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: isAnimating ? 12 : -12, y: isAnimating ? 37 : -37)
            .opacity(isAnimating ? 1 : 0.3)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct VerticalArrowAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? 15 : -15)
            .opacity(isAnimating ? 1 : 0.3)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct HighlightPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct TodayExpenseFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct GreetingFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct AppTourOverlay: View {
    let highlightFrame: CGRect
    let secondFrame: CGRect?
    let incomeFrames: [CGRect]
    let walletFrames: [CGRect]
    let dragWalletFrames: [CGRect]
    let goalsFrames: [CGRect]
    let expensesFrames: [CGRect]
    let walletsRect: CGRect?
    let incomeRect: CGRect?
    let operationsGoalsFrame: CGRect?
    let operationsExpensesFrame: CGRect?
    let title: String
    let description: String
    let onNext: () -> Void
    let onPrev: (() -> Void)?
    let onSkip: () -> Void
    var body: some View {
        let screenHeight = UIScreen.main.bounds.height
        let tabBarHeight: CGFloat = 60
        let maxY = min(highlightFrame.maxY, screenHeight - tabBarHeight)
        let safeHeight = max(0, maxY - highlightFrame.minY)
        let safeFrame = CGRect(x: highlightFrame.minX, y: highlightFrame.minY, width: highlightFrame.width, height: safeHeight)
        let yOffset: CGFloat = (title == "operations_expenses_title".localized) ? 1 : 0
        let isDragStep = title == "drag_income_to_wallet_title".localized
        let isWalletDragStep = title == "drag_wallet_to_goals_expenses_title".localized
        let _ = print("🔍 DEBUG: title=\(title), isDragStep=\(isDragStep), isWalletDragStep=\(isWalletDragStep)")
        if safeFrame.width > 0 && safeFrame.height > 0 && safeFrame.origin.x.isFinite && safeFrame.origin.y.isFinite {
            ZStack(alignment: .topLeading) {
                // --- СЛОЙ 1: затемнение и дырки ---
                if isDragStep, let walletsRect = walletsRect, let incomeRect = incomeRect {
                    Color.black.opacity(0.7)
                        .mask(
                            Rectangle()
                                .overlay(
                                    Group {
                                        // Дырка по всей секции доходов
                                        RoundedRectangle(cornerRadius: 16)
                                            .frame(width: incomeRect.width, height: incomeRect.height)
                                            .position(x: incomeRect.midX, y: incomeRect.midY)
                                            .blendMode(.destinationOut)
                                        // Дырка по всей секции кошельков
                                        RoundedRectangle(cornerRadius: 16)
                                            .frame(width: walletsRect.width, height: walletsRect.height)
                                            .position(x: walletsRect.midX, y: walletsRect.midY)
                                            .blendMode(.destinationOut)
                                    }
                                )
                        )
                        .compositingGroup()
                        .edgesIgnoringSafeArea(.all)


                } else if isDragStep, !incomeFrames.isEmpty, !walletFrames.isEmpty {
                    Color.black.opacity(0.7)
                        .mask(
                            Rectangle()
                                .overlay(
                                    Group {
                                        ForEach(incomeFrames.indices, id: \ .self) { i in
                                            let f = incomeFrames[i]
                                            RoundedRectangle(cornerRadius: 12)
                                                .frame(width: f.width, height: f.height)
                                                .position(x: f.midX, y: f.midY)
                                                .blendMode(.destinationOut)
                                        }
                                        ForEach(walletFrames.indices, id: \ .self) { i in
                                            let f = walletFrames[i]
                                            RoundedRectangle(cornerRadius: 12)
                                                .frame(width: f.width, height: f.height)
                                                .position(x: f.midX, y: f.midY)
                                                .blendMode(.destinationOut)
                                        }
                                    }
                                )
                        )
                        .compositingGroup()
                        .edgesIgnoringSafeArea(.all)
                } else if let second = secondFrame, title == "drag_income_to_wallet_title".localized {
                    // fallback: двойная подсветка
                    Color.black.opacity(0.7)
                        .mask(
                            Rectangle()
                                .overlay(
                                    Group {
                                        RoundedRectangle(cornerRadius: 12)
                                            .frame(width: safeFrame.width, height: safeFrame.height)
                                            .position(x: safeFrame.midX, y: safeFrame.midY + yOffset)
                                            .blendMode(.destinationOut)
                                        RoundedRectangle(cornerRadius: 12)
                                            .frame(width: second.width, height: second.height)
                                            .position(x: second.midX, y: second.midY)
                                            .blendMode(.destinationOut)
                                    }
                                )
                        )
                        .compositingGroup()
                        .edgesIgnoringSafeArea(.all)
                } else if isWalletDragStep {
                    // Выделение для перевода с кошелька - отдельные окошки
                    Color.black.opacity(0.7)
                        .mask(
                            Rectangle()
                                .overlay(
                                    Group {
                                        // Окошко для секции кошельков
                                        if let walletsRect = walletsRect {
                                            RoundedRectangle(cornerRadius: 16)
                                                .frame(width: walletsRect.width + 20, height: walletsRect.height + 20)
                                                .position(x: walletsRect.midX, y: walletsRect.midY)
                                                .blendMode(.destinationOut)
                                        }
                                        
                                        // Окошко для секции целей
                                        if let goalsRect = operationsGoalsFrame {
                                            RoundedRectangle(cornerRadius: 16)
                                                .frame(width: goalsRect.width + 20, height: goalsRect.height + 20)
                                                .position(x: goalsRect.midX, y: goalsRect.midY)
                                                .blendMode(.destinationOut)
                                        }
                                        
                                        // Окошко для секции расходов
                                        if let expensesRect = operationsExpensesFrame {
                                            RoundedRectangle(cornerRadius: 16)
                                                .frame(width: expensesRect.width + 20, height: expensesRect.height + 20)
                                                .position(x: expensesRect.midX, y: expensesRect.midY)
                                                .blendMode(.destinationOut)
                                        }
                                    }
                                )
                        )
                        .compositingGroup()
                        .edgesIgnoringSafeArea(.all)
                } else if title == "tour_complete_title".localized {
                    // Для завершающего шага - только затемнение без выделения
                    let _ = print("🎉 Отображаем завершающий шаг: \(title)")
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                } else if isWalletDragStep {
                    let _ = print("🎯 Отображаем isWalletDragStep: \(title)")
                    // Выделение для перевода с кошелька - отдельные окошки
                    Color.black.opacity(0.7)
                        .mask(
                            Rectangle()
                                .overlay(
                                    Group {
                                        // Окошко для секции кошельков
                                        if let walletsRect = walletsRect {
                                            RoundedRectangle(cornerRadius: 16)
                                                .frame(width: walletsRect.width + 20, height: walletsRect.height + 20)
                                                .position(x: walletsRect.midX, y: walletsRect.midY)
                                                .blendMode(.destinationOut)
                                        }
                                        
                                        // Окошко для секции целей
                                        if let goalsRect = operationsGoalsFrame {
                                            RoundedRectangle(cornerRadius: 16)
                                                .frame(width: goalsRect.width + 20, height: goalsRect.height + 20)
                                                .position(x: goalsRect.midX, y: goalsRect.midY)
                                                .blendMode(.destinationOut)
                                        }
                                        
                                        // Окошко для секции расходов
                                        if let expensesRect = operationsExpensesFrame {
                                            RoundedRectangle(cornerRadius: 16)
                                                .frame(width: expensesRect.width + 20, height: expensesRect.height + 20)
                                                .position(x: expensesRect.midX, y: expensesRect.midY)
                                                .blendMode(.destinationOut)
                                        }
                                    }
                                )
                        )
                        .compositingGroup()
                        .edgesIgnoringSafeArea(.all)
                } else {
                    let _ = print("🔍 Попадаем в блок else для title: \(title)")
                    Color.black.opacity(0.7)
                        .mask(
                            Rectangle()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .frame(width: safeFrame.width, height: safeFrame.height)
                                        .position(x: safeFrame.midX, y: safeFrame.midY + yOffset)
                                        .blendMode(.destinationOut)
                                )
                        )
                        .compositingGroup()
                        .edgesIgnoringSafeArea(.all)
                }
                // --- СЛОЙ 2: стрелки от зарплаты к кошелькам ---
                if isDragStep {
                    // Временная отладочная информация
                    let _ = print("🔴 DRAWING ARROWS: isDragStep=\(isDragStep)")
                    
                    // Координаты для стрелок - точно над иконками
                    let screenWidth = UIScreen.main.bounds.width
                    let salaryX = screenWidth * 0.15  // Позиция зарплаты - левее
                    let cardX = screenWidth * 0.15    // Позиция карты - прямо под зарплатой
                    let cashX = screenWidth * 0.35    // Позиция наличных - правее
                    let salaryY: CGFloat = 110        // Y позиция зарплаты - выше
                    let cardY: CGFloat = 200          // Y позиция карты - ближе к зарплате
                    let cashY: CGFloat = 200          // Y позиция наличных - ближе к зарплате
                    
                    // Стрелка 1: Зарплата → Карта (короткая, вертикальная)
                    Path { path in
                        path.move(to: CGPoint(x: salaryX, y: salaryY))
                        path.addLine(to: CGPoint(x: cardX, y: cardY))
                    }
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6]))
                    .shadow(color: .black, radius: 2)
                    .zIndex(100)
                    
                    // Анимированная точка на стрелке к карте (вертикальная)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .position(x: (salaryX + cardX) * 0.5, y: (salaryY + cardY) * 0.5)
                        .modifier(VerticalArrowAnimationModifier())
                        .zIndex(101)
                    
                    // Стрелка 2: Зарплата → Наличные (короткая, по диагонали)
                    Path { path in
                        path.move(to: CGPoint(x: salaryX, y: salaryY))
                        path.addLine(to: CGPoint(x: cashX, y: cashY))
                    }
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6]))
                    .shadow(color: .black, radius: 2)
                    .zIndex(100)
                    
                    // Анимированная точка на стрелке к наличным (диагональная)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .position(x: (salaryX + cashX) * 0.5, y: (salaryY + cashY) * 0.5)
                        .modifier(DiagonalArrowAnimationModifier())
                        .zIndex(101)
                    

                }
                
                // --- СЛОЙ 3: стрелки от кошелька к целям и расходам ---
                if isWalletDragStep {
                    // Координаты для стрелок от кошелька
                    let screenWidth = UIScreen.main.bounds.width
                    let cardX = screenWidth * 0.15    // Позиция карты
                    let goalX = screenWidth * 0.15    // Позиция целей (под картой)
                    let expenseX = screenWidth * 0.35  // Позиция второй иконки расходов
                    let cardY: CGFloat = 280          // Y позиция карты
                    let goalY: CGFloat = 350          // Y позиция целей (ниже карты)
                    let expenseY: CGFloat = 500       // Y позиция расходов
                    
                    // Стрелка 1: Карта → Цели (вертикальная)
                    Path { path in
                        path.move(to: CGPoint(x: cardX, y: cardY))
                        path.addLine(to: CGPoint(x: goalX, y: goalY))
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6]))
                    .shadow(color: .black, radius: 2)
                    .zIndex(100)
                    
                    // Анимированная точка на стрелке к целям (вертикальная)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .position(x: (cardX + goalX) * 0.5, y: (cardY + goalY) * 0.5)
                        .modifier(VerticalArrowAnimationModifier())
                        .zIndex(101)
                    
                    // Стрелка 2: Карта → Расходы (горизонтальная)
                    Path { path in
                        path.move(to: CGPoint(x: cardX, y: cardY))
                        path.addLine(to: CGPoint(x: expenseX, y: expenseY))
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6]))
                    .shadow(color: .black, radius: 2)
                    .zIndex(100)
                    
                    // Анимированная точка на стрелке к расходам (горизонтальная)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .position(x: (cardX + expenseX) * 0.5, y: (cardY + expenseY) * 0.5)
                        .modifier(CardToExpenseArrowAnimationModifier())
                        .zIndex(101)
                }
                
                // --- СЛОЙ 4: текст для перевода с кошелька ---
                if isWalletDragStep {
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.headline).bold().fontWeight(.heavy)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(description)
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        HStack(spacing: 16) {
                            Button("back".localized, action: { onPrev?() })
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(Color.white.opacity(0.18))
                                .cornerRadius(8)
                            Button("next".localized, action: { onNext() })
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        Button("skip".localized, action: onSkip)
                            .font(.footnote).bold()
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: UIScreen.main.bounds.width/2, y: 70)
                } else if title == "tour_complete_title".localized {
                    let _ = print("🎉 Отображаем завершающий шаг в отдельном блоке: \(title)")
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.headline).bold().fontWeight(.heavy)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(description)
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        HStack(spacing: 16) {
                            Button("finish".localized, action: onSkip)
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: UIScreen.main.bounds.width/2, y: 200)
                } else if title == "operations_expenses_title".localized || title == "operations_wallets_title".localized {
                    let _ = print("🔍 Попадаем в блок Расходы/Кошельки для title: \(title)")
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.headline).bold().fontWeight(.heavy)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(description)
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        HStack(spacing: 16) {
                            Button("back".localized, action: { onPrev?() })
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(Color.white.opacity(0.18))
                                .cornerRadius(8)
                            Button("next".localized, action: { onNext() })
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        Button("skip".localized, action: onSkip)
                            .font(.footnote).bold()
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: UIScreen.main.bounds.width/2, y: {
                        if title == "operations_wallets_title".localized {
                            return max(walletsRect?.maxY ?? 0 + 350, safeFrame.minY + 250)
                        } else {
                            return max(walletsRect?.maxY ?? 0 - 100, safeFrame.minY - 200)
                        }
                    }())
                } else if title == "tour_complete_title".localized {
                    let _ = print("🔍 Попадаем в блок Отлично! Вы готовы для title: \(title)")
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.headline).bold().fontWeight(.heavy)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(description)
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        if isDragStep {
                            VStack(spacing: 4) {
                                Text("wallet_replenish_instruction".localized)
                                    .font(.caption).bold()
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black, radius: 2, x: 0, y: 1)
                                    .multilineTextAlignment(.center)
                                Text("drag_income_step1".localized)
                                    .font(.caption2).bold()
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 1, x: 0, y: 1)
                                    .multilineTextAlignment(.center)
                                Text("drag_income_step2".localized)
                                    .font(.caption2).bold()
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 1, x: 0, y: 1)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                        }
                        HStack(spacing: 16) {
                            Button("back".localized, action: { onPrev?() })
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(Color.white.opacity(0.18))
                                .cornerRadius(8)
                            Button("next".localized, action: { onNext() })
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        Button("skip".localized, action: onSkip)
                            .font(.footnote).bold()
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: UIScreen.main.bounds.width/2, y: {
                        if title == "operations_wallets_title".localized {
                            return max(walletsRect?.maxY ?? 0 + 300, safeFrame.minY + 200)
                        } else {
                            return max(walletsRect?.maxY ?? 0 - 100, safeFrame.minY - 200)
                        }
                    }())
                } else {
                    let _ = print("🔍 Попадаем в текстовый блок else для title: \(title)")
                    let _ = print("🔍 Проверяем условие title == 'Отлично! Вы готовы': \(title == "tour_complete_title".localized)")
                    let _ = print("🔍 Точное значение title: '\(title)'")
                    let _ = print("🔍 Длина title: \(title.count)")
                    if title == "tour_complete_title".localized {
                        let _ = print("🎉 НАЙДЕН ЗАВЕРШАЮЩИЙ ШАГ в текстовом блоке else!")
                    }
                    let spacerHeight = safeFrame.maxY.isFinite && safeFrame.maxY > 0 ? safeFrame.maxY - 2 : 0
                    VStack(spacing: 8) {
                        if title == "tour_complete_title".localized {
                            let _ = print("🎉 Отображаем завершающий шаг в текстовом блоке else: \(title)")
                            Text(title)
                                .font(.headline).bold().fontWeight(.heavy)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3, x: 0, y: 1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text(description)
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3, x: 0, y: 1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                            HStack(spacing: 16) {
                                Button("finish".localized, action: onSkip)
                                    .font(.subheadline).bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18).padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else if title == "tour_complete_title".localized {
                            let _ = print("🎉 Отображаем завершающий шаг в текстовом блоке else: \(title)")
                            Text(title)
                                .font(.headline).bold().fontWeight(.heavy)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3, x: 0, y: 1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text(description)
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3, x: 0, y: 1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                            HStack(spacing: 16) {
                                Button("finish".localized, action: onSkip)
                                    .font(.subheadline).bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18).padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else if !isDragStep {
                            if title != "Доходы" && title != "Кошельки" {
                                Spacer().frame(height: spacerHeight)
                            }
                            Text(title)
                                .font(.headline).bold().fontWeight(.heavy)
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3, x: 0, y: 1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text(description)
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3, x: 0, y: 1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        if isDragStep {
                            VStack(spacing: 8) {
                                Text("wallet_replenish_instruction".localized)
                                    .font(.headline).bold().fontWeight(.heavy)
                                    .foregroundColor(.yellow)
                                    .shadow(color: .black, radius: 3, x: 0, y: 1)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("drag_income_step1".localized)
                                        .font(.subheadline).bold()
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 2, x: 0, y: 1)
                                        .multilineTextAlignment(.center)
                                    Text("drag_income_step2".localized)
                                        .font(.subheadline).bold()
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 2, x: 0, y: 1)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        HStack(spacing: 16) {
                            Button("back".localized, action: { onPrev?() })
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(Color.white.opacity(0.18))
                                .cornerRadius(8)
                            Button("next".localized, action: { onNext() })
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 18).padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        Button("skip".localized, action: onSkip)
                            .font(.footnote).bold()
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .position(x: UIScreen.main.bounds.width/2, y: {
                        if isDragStep {
                            return max(walletsRect?.maxY ?? 0 + 450, safeFrame.minY + 350)
                        } else if title == "last_transactions_title".localized {
                            return max(walletsRect?.maxY ?? 0 - 50, safeFrame.minY - 150)
                        } else if title == "operations_income_title".localized {
                            return max(walletsRect?.maxY ?? 0 - 150, safeFrame.minY - 250)
                        } else if title == "operations_wallets_title".localized {
                            return max(walletsRect?.maxY ?? 0 + 50, safeFrame.minY - 50)
                        } else if title == "operations_goals_title".localized {
                            return max(walletsRect?.maxY ?? 0 + 100, safeFrame.minY - 80)
                        } else {
                            return max(walletsRect?.maxY ?? 0 + 100, safeFrame.minY + 100)
                        }
                    }())
                }
            }
        } else {
            EmptyView()
        }
    }
}

struct GoalsCarouselView: View {
    @EnvironmentObject var viewModel: GoalsViewModel
    @EnvironmentObject var walletsVM: WalletsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var tourManager: AppTourManager
    @Binding var selectedTab: Int
    @Binding var todayExpenseFrame: CGRect
    @Binding var createGoalFrame: CGRect
    @Binding var lastTransactionsFrame: CGRect
    @Binding var dragIncomeFrames: [CGRect]
    @Binding var goalsFrames: [CGRect]
    @Binding var expensesFrames: [CGRect]
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showAIChat = false
    @State private var showCreateGoalSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                VStack(spacing: 4) {
                    GreetingView(userName: viewModel.userName)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .id("topOfScreen")
                    ZStack {
                            TodayExpenseView(todayExpense: viewModel.todayExpense, frame: $todayExpenseFrame)
                                .padding(.top, 6)
                        }
                    .padding(.horizontal)
                    Spacer()
                    if viewModel.goals.isEmpty {
                        ZStack {
                            EmptyGoalView(showCreateGoalSheet: $showCreateGoalSheet) { name, sum, icon, color, currency, initial, planPeriod, planAmount, reminderPeriod, selectedWeekday, selectedMonthDay, selectedTime in
                                print("DEBUG: GoalsCarouselView - received selectedMonthDay: \(selectedMonthDay ?? -1)")
                                viewModel.createGoal(name: name, targetAmount: sum, currentAmount: initial, currency: currency.isEmpty ? "₸" : currency, icon: icon?.isEmpty == false ? icon! : "leaf.circle.fill", color: color?.isEmpty == false ? color! : "#00FF00", planPeriod: planPeriod, planAmount: planAmount, reminderPeriod: reminderPeriod, selectedWeekday: selectedWeekday, selectedMonthDay: selectedMonthDay, selectedTime: selectedTime)
                                showCreateGoalSheet = false
                            }
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        createGoalFrame = geo.frame(in: .named("tourRoot"))
                                    }
                                    .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                                        createGoalFrame = newValue
                                    }
                            }
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
                    ZStack {
                        LastTransactionsView(
                            onShowHistory: { selectedTab = 0 },
                            todayTransactions: viewModel.todayTransactions
                        )
                        .id(AppLanguageManager.shared.currentLanguage)
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    lastTransactionsFrame = geo.frame(in: .named("tourRoot"))
                                }
                                .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                                    lastTransactionsFrame = newValue
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                }
                .onChange(of: tourManager.currentStep) { _, newStep in
                    // Скролл наверх при переходе к шагам главного экрана
                    if newStep == .todayExpense || newStep == .createGoal || newStep == .lastTransactions {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            scrollProxy.scrollTo("topOfScreen", anchor: .top)
                        }
                    }
                }
                Spacer().frame(height: 20)
                    // --- AI SearchBar ---
                    SearchBar(
                        placeholder: "Добавить расходы? Как быстрее накопить? Анализ расходов?",
                        text: .constant("")
                        , iconName: "поисковик"
                        , iconOnRight: true
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showAIChat = true
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .frame(height: 44)
                    .sheet(isPresented: $showAIChat) {
                        AIChatView()
                    }
                }
            }
            // overlay теперь только в ContentView
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
    @Binding var frame: CGRect
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
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        frame = geo.frame(in: .named("tourRoot"))
                    }
                    .onChange(of: geo.frame(in: .named("tourRoot"))) { _, newValue in
                        frame = newValue
                    }
            }
        )
        .onLanguageChange()
    }
}

struct EmptyGoalView: View {
    @Binding var showCreateGoalSheet: Bool
    var onCreate: (String, Double, String?, String?, String, Double, PlanPeriod?, Double?, PlanPeriod?, Int?, Int?, Date?) -> Void
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
            CreateItemSheet(type: .goal) { name, sum, icon, color, currency, initial, planPeriod, planAmount, reminderPeriod, selectedWeekday, selectedMonthDay, selectedTime in
                print("DEBUG: EmptyGoalView - received selectedMonthDay: \(selectedMonthDay ?? -1)")
                print("DEBUG: EmptyGoalView - received selectedWeekday: \(selectedWeekday ?? -1)")
                print("DEBUG: EmptyGoalView - received reminderPeriod: \(reminderPeriod?.rawValue ?? "nil")")
                onCreate(name, sum, icon, color, currency, initial, planPeriod, planAmount, reminderPeriod, selectedWeekday, selectedMonthDay, selectedTime)
            }
            .id(UUID())
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
                OperationsView(operationsIncomeFrame: .constant(.zero), operationsWalletsFrame: .constant(.zero), operationsGoalsFrame: .constant(.zero), operationsExpensesFrame: .constant(.zero), dragWalletFrames: .constant([]), dragIncomeFrames: .constant([]), goalsFrames: .constant([]), expensesFrames: .constant([]))
                    .id(UUID())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .onAppear {
            // Принудительно инициализируем состояние при появлении
            _ = goal
        }
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
    @State private var showOperations = false
    
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
            .frame(height: 44)
        }
        .sheet(isPresented: $showOperations) {
            OperationsView(operationsIncomeFrame: .constant(.zero), operationsWalletsFrame: .constant(.zero), operationsGoalsFrame: .constant(.zero), operationsExpensesFrame: .constant(.zero), dragWalletFrames: .constant([]), dragIncomeFrames: .constant([]), goalsFrames: .constant([]), expensesFrames: .constant([]))
                .id(UUID())
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
                VStack(spacing: 0) {
                    ForEach(Array(todayTransactions.enumerated()), id: \.element.id) { index, tx in
                        VStack(spacing: 0) {
                            TransactionCell(transaction: tx)
                            if index < todayTransactions.count - 1 {
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .frame(height: todayTransactions.isEmpty ? 44 : 3 * 56)
        }
        .padding(8)
        .background(Color(.systemGray6))
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

