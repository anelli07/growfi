import Foundation
 
struct Wallet: Identifiable, Codable {
    let id: Int
    var name: String
    var balance: Double
    var iconName: String? // SF Symbol или кастомная иконка
    var colorHex: String? // hex-цвет для круга
} 