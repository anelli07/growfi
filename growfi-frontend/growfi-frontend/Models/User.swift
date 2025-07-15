import Foundation

struct User: Identifiable, Codable {
    let id: Int
    let full_name: String?
    let email: String
} 