import SwiftUI

struct ContentView: View {
    @EnvironmentObject var goalsViewModel: GoalsViewModel
    @EnvironmentObject var walletsVM: WalletsViewModel
    @EnvironmentObject var expensesVM: ExpensesViewModel
    @EnvironmentObject var incomesVM: IncomesViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var tourManager: AppTourManager

    var onLogout: () -> Void

    @State private var selectedTab = 2 // Главный экран — 'Цели'
    @State private var todayExpenseFrame: CGRect = .zero
    @State private var createGoalFrame: CGRect = .zero
    @State private var lastTransactionsFrame: CGRect = .zero
    @State private var operationsIncomeFrame: CGRect = .zero
    @State private var operationsWalletsFrame: CGRect = .zero
    @State private var operationsGoalsFrame: CGRect = .zero
    @State private var operationsExpensesFrame: CGRect = .zero
    @State private var dragIncomeFrames: [CGRect] = []
    @State private var dragWalletFrames: [CGRect] = []
    @State private var goalsFrames: [CGRect] = []
    @State private var expensesFrames: [CGRect] = []

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HistoryView()
                    .environmentObject(historyVM)
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle")
                        Text("history".localized)
                    }
                    .tag(0)
                                 OperationsView(operationsIncomeFrame: $operationsIncomeFrame, operationsWalletsFrame: $operationsWalletsFrame, operationsGoalsFrame: $operationsGoalsFrame, operationsExpensesFrame: $operationsExpensesFrame, dragWalletFrames: $dragWalletFrames, dragIncomeFrames: $dragIncomeFrames, goalsFrames: $goalsFrames, expensesFrames: $expensesFrames)
                    .tabItem {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("operations".localized)
                    }
                    .tag(1)
                                 GoalsCarouselView(selectedTab: $selectedTab, todayExpenseFrame: $todayExpenseFrame, createGoalFrame: $createGoalFrame, lastTransactionsFrame: $lastTransactionsFrame, dragIncomeFrames: $dragIncomeFrames, goalsFrames: $goalsFrames, expensesFrames: $expensesFrames)
                    .tabItem {
                        Image(systemName: "leaf.circle.fill")
                        Text("goals".localized)
                    }
                    .tag(2)
                AnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.pie.fill")
                        Text("analytics".localized)
                    }
                    .tag(3)
                SettingsView(onLogout: onLogout, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("settings".localized)
                    }
                    .tag(4)
            }
            .coordinateSpace(name: "tourRoot")
            .onChange(of: tourManager.currentStep) { _, newStep in
                // Все шаги операций показываются на странице операций
                if newStep == .operationsIncome || newStep == .operationsWallets || newStep == .operationsGoals || newStep == .operationsExpenses || newStep == .dragIncomeToWallet || newStep == .dragWalletToGoalsExpenses {
                    selectedTab = 1
                }
                // Переключаемся на главный экран только для шагов главного экрана
                if newStep == .todayExpense || newStep == .createGoal || newStep == .lastTransactions {
                    selectedTab = 2
                }
            }

            // Overlay always on top
            if tourManager.isTourActive {
                let _ = print("🎨 ContentView: isTourActive=true, currentStep=\(tourManager.currentStep)")
                let pad: CGFloat = 8
                let frame: CGRect = {
                    switch tourManager.currentStep {
                    case .todayExpense:
                        return CGRect(
                            x: todayExpenseFrame.minX - pad,
                            y: todayExpenseFrame.minY - pad,
                            width: todayExpenseFrame.width + pad * 2,
                            height: todayExpenseFrame.height + pad * 2
                        )
                    case .createGoal:
                        return CGRect(
                            x: createGoalFrame.minX - pad,
                            y: createGoalFrame.minY - pad,
                            width: createGoalFrame.width + pad * 2,
                            height: createGoalFrame.height + pad * 2
                        )
                    case .lastTransactions:
                        return CGRect(
                            x: lastTransactionsFrame.minX - pad,
                            y: lastTransactionsFrame.minY - pad,
                            width: lastTransactionsFrame.width + pad * 2,
                            height: lastTransactionsFrame.height + pad * 2
                        )
                    case .operationsIncome:
                        return CGRect(
                            x: operationsIncomeFrame.minX - pad,
                            y: operationsIncomeFrame.minY - pad,
                            width: operationsIncomeFrame.width + pad * 2,
                            height: operationsIncomeFrame.height + pad * 2
                        )
                    case .operationsWallets:
                        return CGRect(
                            x: operationsWalletsFrame.minX - pad,
                            y: operationsWalletsFrame.minY - pad,
                            width: operationsWalletsFrame.width + pad * 2,
                            height: operationsWalletsFrame.height + pad * 2
                        )
                    case .operationsGoals:
                        return CGRect(
                            x: operationsGoalsFrame.minX - pad,
                            y: operationsGoalsFrame.minY - pad,
                            width: operationsGoalsFrame.width + pad * 2,
                            height: operationsGoalsFrame.height + pad * 2
                        )
                    case .operationsExpenses:
                        return CGRect(
                            x: operationsExpensesFrame.minX - pad,
                            y: operationsExpensesFrame.minY - pad,
                            width: operationsExpensesFrame.width + pad * 2,
                            height: operationsExpensesFrame.height + pad * 2
                        )
                    case .dragIncomeToWallet:
                        // Используем первый доход из массива или fallback
                        if let firstIncome = dragIncomeFrames.first {
                            return CGRect(
                                x: firstIncome.minX - pad,
                                y: firstIncome.minY - pad,
                                width: firstIncome.width + pad * 2,
                                height: firstIncome.height + pad * 2
                            )
                        } else {
                            return CGRect(x: 0, y: 0, width: 100, height: 100) // fallback
                        }
                    case .dragWalletToGoalsExpenses:
                        // Используем первый кошелек из массива или fallback
                        if let firstWallet = dragWalletFrames.first {
                            return CGRect(
                                x: firstWallet.minX - pad,
                                y: firstWallet.minY - pad,
                                width: firstWallet.width + pad * 2,
                                height: firstWallet.height + pad * 2
                            )
                        } else {
                            return CGRect(x: 0, y: 0, width: 100, height: 100) // fallback
                        }
                    case .tourComplete:
                        // Для завершающего шага используем весь экран
                        return CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    }
                }()
                
                let walletsRect: CGRect = operationsWalletsFrame
                let incomeRect: CGRect = operationsIncomeFrame
                AppTourOverlay(
                    highlightFrame: frame,
                    secondFrame: tourManager.currentStep == .dragIncomeToWallet ? walletsRect : nil,
                    incomeFrames: [],
                    walletFrames: [],
                    dragWalletFrames: dragWalletFrames,
                    goalsFrames: goalsFrames,
                    expensesFrames: expensesFrames,
                    walletsRect: walletsRect,
                    incomeRect: incomeRect,
                    operationsGoalsFrame: operationsGoalsFrame,
                    operationsExpensesFrame: operationsExpensesFrame,
                    title: tourManager.currentStep.title,
                    description: tourManager.currentStep.description,
                    onNext: { tourManager.nextStep() },
                    onPrev: { tourManager.prevStep() },
                    onSkip: { tourManager.skipTour() }
                )
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(onLogout: {})
            .environmentObject(GoalsViewModel())
            .environmentObject(WalletsViewModel())
            .environmentObject(ExpensesViewModel())
            .environmentObject(IncomesViewModel())
    }
}


