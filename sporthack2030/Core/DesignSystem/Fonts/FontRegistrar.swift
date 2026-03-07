import Foundation
import CoreText

enum FontRegistrar {
    static func registerAppFonts() {
        registerFonts(atSubdirectory: "Resources/Fonts")
        registerFonts(atSubdirectory: nil)
    }

    static func registeredIBMFonts() -> [String] {
        let names = CTFontManagerCopyAvailablePostScriptNames() as? [String] ?? []
        return names.filter { $0.localizedCaseInsensitiveContains("IBMPlexSansArabic") }.sorted()
    }

    private static func registerFonts(atSubdirectory subdirectory: String?) {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: subdirectory) else {
            return
        }

        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
