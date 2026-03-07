import SwiftUI

extension Color {
    init(hex: String) {
        let cleanedHex = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var int: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch cleanedHex.count {
        case 3:
            (r, g, b) = (((int >> 8) * 17), ((int >> 4 & 0xF) * 17), ((int & 0xF) * 17))
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
