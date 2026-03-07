//
//  sporthack2030App.swift
//  sporthack2030
//
//  Created by Ahmed on 18/09/1447 AH.
//

import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

@main
struct sporthack2030App: App {
    init() {
        FontRegistrar.registerAppFonts()
#if DEBUG
        print("Registered IBM fonts: \(FontRegistrar.registeredIBMFonts())")
#endif

#if os(iOS)
        if let navTitleFont = UIFont(name: AppFontName.semiBold, size: 18),
           let navLargeTitleFont = UIFont(name: AppFontName.bold, size: 32) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.font: navTitleFont]
            navBarAppearance.largeTitleTextAttributes = [.font: navLargeTitleFont]

            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        }

        if let tabFont = UIFont(name: AppFontName.medium, size: 11) {
            UITabBarItem.appearance().setTitleTextAttributes([.font: tabFont], for: .normal)
            UITabBarItem.appearance().setTitleTextAttributes([.font: tabFont], for: .selected)
        }
#endif
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, .rightToLeft)
                .font(.appFont(.regular, size: 16))
        }
        .modelContainer(sharedModelContainer)
    }
}
