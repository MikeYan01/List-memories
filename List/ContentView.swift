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
    
    var body: some View {
        TabView {
            RestaurantView()
                .tabItem {
                    Label("tab.restaurant".localized(), systemImage: "fork.knife")
                }
            
            BeverageView()
                .tabItem {
                    Label("tab.beverage".localized(), systemImage: "wineglass")
                }
            
            TravelView()
                .tabItem {
                    Label("tab.travel".localized(), systemImage: "airplane.departure")
                }
            
            RecreationView()
                .tabItem {
                    Label("tab.recreation".localized(), systemImage: "theatermasks.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("tab.settings".localized(), systemImage: "gearshape.fill")
                }
        }
        .tint(.pink)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
