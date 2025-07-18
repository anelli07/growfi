import SwiftUI

struct GoalCardView: View {
    let goal: Goal
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image("plant_stage_\(goal.growthStage)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isSelected ? 100 : 70, height: isSelected ? 100 : 70)
                .shadow(color: .black.opacity(isSelected ? 0.15 : 0.05), radius: isSelected ? 12 : 4, x: 0, y: 6)

            Text(goal.name.localizedIfDefault)
                .font(.subheadline)
                .foregroundColor(.primary)
                .opacity(isSelected ? 1 : 0.5)
        }
        .animation(.easeInOut(duration: 0.25), value: isSelected)
    }
}
