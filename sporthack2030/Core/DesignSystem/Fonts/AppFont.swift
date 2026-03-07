import SwiftUI

enum AppFontName {
    static let regular = "IBMPlexSansArabic-Regular"
    static let bold = "IBMPlexSansArabic-Bold"
    static let medium = "IBMPlexSansArabic-Medium"
    static let semiBold = "IBMPlexSansArabic-SemiBold"
}

enum AppFontWeight {
    case regular
    case medium
    case semiBold
    case bold
}

extension Font {
    static func appFont(_ weight: AppFontWeight = .regular, size: CGFloat) -> Font {
        let fontName: String

        switch weight {
        case .regular:
            fontName = AppFontName.regular
        case .medium:
            fontName = AppFontName.medium
        case .semiBold:
            fontName = AppFontName.semiBold
        case .bold:
            fontName = AppFontName.bold
        }

        return .custom(fontName, size: size)
    }
}
