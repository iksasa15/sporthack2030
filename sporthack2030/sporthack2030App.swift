//
//  sporthack2030App.swift
//  sporthack2030
//
//  Created by Ahmed on 18/09/1447 AH.
//

import SwiftUI
import SwiftData

@main
struct sporthack2030App: App {
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
        }
        .modelContainer(sharedModelContainer)
    }
}
