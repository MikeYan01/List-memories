//
//  GlobalSearchView.swift
//  List
//
//  Created by Linyi Yan on 11/4/25.
//

import SwiftUI
import SwiftData

struct GlobalSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var restaurants: [Restaurant]
    @Query private var beverages: [Beverage]
    @Query private var travels: [Travel]
    @Query private var recreations: [Recreation]
    
    @State private var searchText = ""
    
    var searchResults: SearchResults {
        guard !searchText.isEmpty else {
            return SearchResults()
        }
        
        let matchedRestaurants = restaurants.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
        
        let matchedBeverages = beverages.filter {
            $0.shopName.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
        
        let matchedTravels = travels.filter {
            $0.destination.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
        
        let matchedRecreations = recreations.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText) ||
            $0.notes.localizedCaseInsensitiveContains(searchText)
        }
        
        return SearchResults(
            restaurants: matchedRestaurants,
            beverages: matchedBeverages,
            travels: matchedTravels,
            recreations: matchedRecreations
        )
    }
    
    var hasResults: Bool {
        searchResults.totalCount > 0
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if searchText.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "全局搜索",
                        subtitle: "搜索所有记录中的餐厅、饮品、旅行和娱乐"
                    )
                } else if !hasResults {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "没有找到结果",
                        subtitle: "试试其他搜索词"
                    )
                } else {
                    List {
                        if !searchResults.restaurants.isEmpty {
                            Section {
                                ForEach(searchResults.restaurants) { restaurant in
                                    NavigationLink {
                                        RestaurantDetailView(restaurant: restaurant)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(restaurant.name)
                                                .font(.headline)
                                            Text(restaurant.location)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "fork.knife")
                                    Text("餐厅 (\(searchResults.restaurants.count))")
                                }
                                .foregroundStyle(.pink)
                            }
                        }
                        
                        if !searchResults.beverages.isEmpty {
                            Section {
                                ForEach(searchResults.beverages) { beverage in
                                    NavigationLink {
                                        BeverageDetailView(beverage: beverage)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(beverage.shopName)
                                                .font(.headline)
                                            if !beverage.notes.isEmpty {
                                                Text(beverage.notes)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "cup.and.saucer.fill")
                                    Text("饮品 (\(searchResults.beverages.count))")
                                }
                                .foregroundStyle(.orange)
                            }
                        }
                        
                        if !searchResults.travels.isEmpty {
                            Section {
                                ForEach(searchResults.travels) { travel in
                                    NavigationLink {
                                        TravelDetailView(travel: travel)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(travel.destination)
                                                .font(.headline)
                                            Text(travel.plannedDate, style: .date)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "airplane.departure")
                                    Text("旅行 (\(searchResults.travels.count))")
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                        
                        if !searchResults.recreations.isEmpty {
                            Section {
                                ForEach(searchResults.recreations) { recreation in
                                    NavigationLink {
                                        RecreationDetailView(recreation: recreation)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(recreation.type.rawValue)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(.purple.opacity(0.2))
                                                    .foregroundStyle(.purple)
                                                    .clipShape(Capsule())
                                                Text(recreation.name)
                                                    .font(.headline)
                                            }
                                            if !recreation.location.isEmpty {
                                                Text(recreation.location)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "theatermasks.fill")
                                    Text("娱乐 (\(searchResults.recreations.count))")
                                }
                                .foregroundStyle(.purple)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索所有记录")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchResults {
    var restaurants: [Restaurant] = []
    var beverages: [Beverage] = []
    var travels: [Travel] = []
    var recreations: [Recreation] = []
    
    var totalCount: Int {
        restaurants.count + beverages.count + travels.count + recreations.count
    }
}

#Preview {
    GlobalSearchView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
