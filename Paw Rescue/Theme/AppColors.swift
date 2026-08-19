import SwiftUI

enum AppColors {
    // MARK: - Primary
    static let primaryBackground = Color(hex: "FFF6E9")
    static let primaryBlue = Color(hex: "2D4A9A")
    static let secondaryCream = Color(hex: "FFE3B7")
    
    // MARK: - Neutrals
    static let black = Color.black
    static let white = Color.white
    static let gray100 = Color(hex: "F5F5F5")
    static let gray200 = Color(hex: "E5E5E5")
    static let gray300 = Color(hex: "D4D4D4")
    static let gray400 = Color(hex: "A3A3A3")
    static let gray500 = Color(hex: "737373")
    static let gray600 = Color(hex: "525252")
    static let gray700 = Color(hex: "404040")
    
    // MARK: - Pin Colors
    static let pinGreen = Color(hex: "4CAF50")
    static let pinYellow = Color(hex: "FFC107")
    static let pinRed = Color(hex: "E53935")
    
    // MARK: - Status
    static let emergency = Color(hex: "E53935")
    static let warning = Color(hex: "FFC107")
    static let safe = Color(hex: "4CAF50")
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
