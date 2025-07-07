import SwiftUI

struct GoalCardView: View {
    let goal: Goal
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(isSelected ? 1.0 : 0.4))
                    .frame(width: 80, height: 80)
                    .shadow(radius: isSelected ? 6 : 0)
                Image("plant_stage_\(goal.growthStage)")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .opacity(isSelected ? 1.0 : 0.7)
            }
            Text(goal.name)
                .font(.subheadline)
                .opacity(isSelected ? 1.0 : 0.5)
        }
        .frame(width: 120, height: 110)
        .scaleEffect(isSelected ? 1.0 : 0.8)
        .zIndex(isSelected ? 1.0 : 0.0)
    }
} 
