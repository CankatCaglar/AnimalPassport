import SwiftUI

struct Theme {
    static let darkGreen = Color(hex: "797D62")
    static let lightGreen = Color(hex: "9B9B7A")
    static let peach = Color(hex: "D9AE94")
    static let cream = Color(hex: "F1DCA7")
    static let rust = Color(hex: "D08C60")
    static let brown = Color(hex: "997B66")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 