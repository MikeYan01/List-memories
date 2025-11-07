//
//  ContentView.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showChronicle = false
    
    var body: some View {
        TabView {
            RestaurantView(showChronicle: $showChronicle)
                .tabItem {
                    Label("tab.restaurant".localized(), systemImage: "fork.knife")
                }
            
            BeverageView(showChronicle: $showChronicle)
                .tabItem {
                    Label("tab.beverage".localized(), systemImage: "wineglass")
                }
            
            TravelView(showChronicle: $showChronicle)
                .tabItem {
                    Label("tab.travel".localized(), systemImage: "airplane.departure")
                }
            
            RecreationView(showChronicle: $showChronicle)
                .tabItem {
                    Label("tab.recreation".localized(), systemImage: "theatermasks.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("tab.settings".localized(), systemImage: "gearshape.fill")
                }
        }
        .tint(.pink)
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .sheet(isPresented: $showChronicle) {
            ChronicleView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
