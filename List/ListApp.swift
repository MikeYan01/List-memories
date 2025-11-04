//
//  ListApp.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import SwiftUI
import SwiftData

@main
struct ListApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Restaurant.self,
            Beverage.self,
            Travel.self,
            Recreation.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If there's a migration error, try to recreate the container
            print("⚠️ ModelContainer error: \(error)")
            print("🔄 Attempting to reset and recreate...")
            
            // Try to delete the old store and create a fresh one
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ ModelContainer recreated successfully")
                return container
            } catch {
                fatalError("Could not create ModelContainer even after reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
