import Foundation

struct Wallet: Identifiable, Codable {
    let id: Int
    var name: String
    var balance: Double
} 