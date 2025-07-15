import Foundation

struct Goal: Identifiable, Codable {
    let id: Int
    var name: String
    let target_amount: Double
    var current_amount: Double
    let user_id: Int
    let icon: String
    let color: String
    let currency: String

    // Стадия роста (0-9)
    var growthStage: Int {
        guard target_amount > 0 else { return 0 }
        let progress = min(max(current_amount / target_amount, 0), 1)
        return Int(progress * 9)
    }
} 
