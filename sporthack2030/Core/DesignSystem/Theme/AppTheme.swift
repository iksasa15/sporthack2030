import SwiftUI

enum AppTheme {
    enum Light {
        static let background = Color(hex: "#F9FAFB")
        static let card = Color(hex: "#FFFFFF")
        static let primaryText = Color(hex: "#111827")
        static let interactive = Color(hex: "#3B82F6")
        static let preventionAlert = Color(hex: "#EF4444")
        static let cardBorder = Color(hex: "#E5E7EB")
    }

    enum Dark {
        static let background = Color(hex: "#000000")
        static let card = Color(hex: "#1C1C1E")
        static let primaryText = Color(hex: "#FFFFFF")
        static let interactive = Color(hex: "#60A5FA")
        static let preventionAlert = Color(hex: "#F87171")
        static let cardBorder = Color(hex: "#1C1C1E")
    }

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Dark.background : Light.background
    }

    static func card(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Dark.card : Light.card
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Dark.primaryText : Light.primaryText
    }

    static func interactive(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Dark.interactive : Light.interactive
    }

    static func preventionAlert(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Dark.preventionAlert : Light.preventionAlert
    }

    static func cardBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Dark.cardBorder : Light.cardBorder
    }
}
