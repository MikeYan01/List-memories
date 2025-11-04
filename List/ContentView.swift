//
//  ContentView.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            RestaurantView()
                .tabItem {
                    Label("吃", systemImage: "fork.knife")
                }
            
            BeverageView()
                .tabItem {
                    Label("喝", systemImage: "wineglass")
                }
            
            TravelView()
                .tabItem {
                    Label("玩", systemImage: "airplane.departure")
                }
            
            RecreationView()
                .tabItem {
                    Label("乐", systemImage: "theatermasks.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
        .tint(.pink)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
