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
            Tab("tab.restaurant".localized(), systemImage: "fork.knife") {
                RestaurantView(showChronicle: $showChronicle)
            }
            
            Tab("tab.beverage".localized(), systemImage: "wineglass") {
                BeverageView(showChronicle: $showChronicle)
            }
            
            Tab("tab.travel".localized(), systemImage: "airplane.departure") {
                TravelView(showChronicle: $showChronicle)
            }
            
            Tab("tab.recreation".localized(), systemImage: "theatermasks.fill") {
                RecreationView(showChronicle: $showChronicle)
            }
            
            Tab(role: .search) {
                SearchView()
            }
        }
        .tint(.pink)
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .sheet(isPresented: $showChronicle) {
            ChronicleView()
        }
    }
}

// Search view that combines all searchable content
struct SearchView: View {
    @State private var searchText = ""
    @Query(sort: \Restaurant.date, order: .reverse) private var restaurants: [Restaurant]
    @Query(sort: \Beverage.date, order: .reverse) private var beverages: [Beverage]
    @Query(sort: \Travel.plannedDate, order: .reverse) private var travels: [Travel]
    @Query(sort: \Recreation.date, order: .reverse) private var recreations: [Recreation]
    
    private var filteredRestaurants: [Restaurant] {
        guard !searchText.isEmpty else { return restaurants }
        return restaurants.filter { restaurant in
            restaurant.name.localizedCaseInsensitiveContains(searchText) ||
            restaurant.location.localizedCaseInsensitiveContains(searchText) ||
            restaurant.notes.localizedCaseInsensitiveContains(searchText) ||
            restaurant.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    private var filteredBeverages: [Beverage] {
        guard !searchText.isEmpty else { return beverages }
        return beverages.filter { beverage in
            beverage.shopName.localizedCaseInsensitiveContains(searchText) ||
            beverage.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredTravels: [Travel] {
        guard !searchText.isEmpty else { return travels }
        return travels.filter { travel in
            travel.destination.localizedCaseInsensitiveContains(searchText) ||
            travel.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredRecreations: [Recreation] {
        guard !searchText.isEmpty else { return recreations }
        return recreations.filter { recreation in
            recreation.name.localizedCaseInsensitiveContains(searchText) ||
            recreation.location.localizedCaseInsensitiveContains(searchText) ||
            recreation.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Restaurants
                if !filteredRestaurants.isEmpty {
                    Section("tab.restaurant".localized()) {
                        ForEach(filteredRestaurants) { restaurant in
                            NavigationLink {
                                RestaurantDetailView(restaurant: restaurant)
                            } label: {
                                RestaurantRow(restaurant: restaurant)
                            }
                        }
                    }
                }
                
                // Beverages
                if !filteredBeverages.isEmpty {
                    Section("tab.beverage".localized()) {
                        ForEach(filteredBeverages) { beverage in
                            NavigationLink {
                                BeverageDetailView(beverage: beverage)
                            } label: {
                                BeverageRow(beverage: beverage)
                            }
                        }
                    }
                }
                
                // Travels
                if !filteredTravels.isEmpty {
                    Section("tab.travel".localized()) {
                        ForEach(filteredTravels) { travel in
                            NavigationLink {
                                TravelDetailView(travel: travel)
                            } label: {
                                TravelRow(travel: travel)
                            }
                        }
                    }
                }
                
                // Recreations
                if !filteredRecreations.isEmpty {
                    Section("tab.recreation".localized()) {
                        ForEach(filteredRecreations) { recreation in
                            NavigationLink {
                                RecreationDetailView(recreation: recreation)
                            } label: {
                                RecreationRow(recreation: recreation)
                            }
                        }
                    }
                }
                
                // No results
                if !searchText.isEmpty && filteredRestaurants.isEmpty && filteredBeverages.isEmpty && 
                   filteredTravels.isEmpty && filteredRecreations.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("common.search".localized())
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}

