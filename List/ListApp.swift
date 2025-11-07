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
        // Define the current schema
        let schema = Schema([
            Restaurant.self,
            Beverage.self,
            Travel.self,
            Recreation.self,
        ])
        
        // Configure model with CloudKit
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic
        )

        do {
            // Try to create container with current schema
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            print("✅ ModelContainer initialized successfully")
            return container
        } catch {
            print("⚠️ ModelContainer error: \(error)")
            print("🔄 Attempting migration by recreating container...")
            
            // Migration strategy: Delete old database and create fresh one
            // Note: This will lose existing data. For production, use proper versioned schema migration
            let fileManager = FileManager.default
            if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                let shmURL = appSupport.appendingPathComponent("default.store-shm")
                let walURL = appSupport.appendingPathComponent("default.store-wal")
                
                try? fileManager.removeItem(at: storeURL)
                try? fileManager.removeItem(at: shmURL)
                try? fileManager.removeItem(at: walURL)
                
                print("🗑️ Removed old database files")
            }
            
            do {
                let container = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
                print("✅ ModelContainer recreated successfully")
                return container
            } catch {
                fatalError("Could not create ModelContainer even after cleanup: \(error)")
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
