//
//  ChronicleView.swift
//  List
//
//  Created by Linyi Yan on 11/7/25.
//

import SwiftUI
import SwiftData

// Unified timeline event
enum TimelineEvent: Identifiable {
    case restaurant(Restaurant)
    case beverage(Beverage)
    case travel(Travel)
    case recreation(Recreation)
    
    var id: String {
        switch self {
        case .restaurant(let item): return "restaurant-\(item.name)-\(item.date)"
        case .beverage(let item): return "beverage-\(item.shopName)-\(item.date)"
        case .travel(let item): return "travel-\(item.destination)-\(item.plannedDate)"
        case .recreation(let item): return "recreation-\(item.name)-\(item.date)"
        }
    }
    
    var date: Date {
        switch self {
        case .restaurant(let item): return item.date
        case .beverage(let item): return item.date
        case .travel(let item): return item.actualDate ?? item.plannedDate
        case .recreation(let item): return item.date
        }
    }
    
    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .beverage: return "wineglass"
        case .travel: return "airplane.departure"
        case .recreation: return "theatermasks.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .restaurant: return .pink
        case .beverage: return .pink
        case .travel: return .pink
        case .recreation: return .pink
        }
    }
    
    var title: String {
        switch self {
        case .restaurant(let item): return item.name
        case .beverage(let item): return item.shopName
        case .travel(let item): return item.destination
        case .recreation(let item): return item.name
        }
    }
    
    var subtitle: String {
        switch self {
        case .restaurant(let item): return item.location
        case .beverage: return "beverage.title".localized()
        case .travel(let item): 
            return item.actualDate == nil ? "travel.status.planned".localized() : "travel.status.completed".localized()
        case .recreation(let item): return item.type.localizedName
        }
    }
}

struct ChronicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Restaurant.date, order: .reverse) private var restaurants: [Restaurant]
    @Query(sort: \Beverage.date, order: .reverse) private var beverages: [Beverage]
    @Query(sort: \Travel.plannedDate, order: .reverse) private var travels: [Travel]
    @Query(sort: \Recreation.date, order: .reverse) private var recreations: [Recreation]
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var searchText = ""
    @State private var selectedYear: Int?
    
    var allEvents: [TimelineEvent] {
        var events: [TimelineEvent] = []
        events.append(contentsOf: restaurants.map { .restaurant($0) })
        events.append(contentsOf: beverages.map { .beverage($0) })
        events.append(contentsOf: travels.map { .travel($0) })
        events.append(contentsOf: recreations.map { .recreation($0) })
        return events.sorted { $0.date > $1.date }
    }
    
    var filteredEvents: [TimelineEvent] {
        allEvents.filter { event in
            let matchesSearch = searchText.isEmpty || event.title.localizedCaseInsensitiveContains(searchText)
            let matchesYear = selectedYear == nil || Calendar.current.component(.year, from: event.date) == selectedYear
            return matchesSearch && matchesYear
        }
    }
    
    var availableYears: [Int] {
        let years = Set(allEvents.map { Calendar.current.component(.year, from: $0.date) })
        return Array(years).sorted(by: >)
    }
    
    var groupedEvents: [(String, [TimelineEvent])] {
        let grouped = Dictionary(grouping: filteredEvents) { event in
            let components = Calendar.current.dateComponents([.year, .month], from: event.date)
            return "\(components.year!)-\(String(format: "%02d", components.month!))"
        }
        return grouped.sorted { $0.key > $1.key }.map { (key, events) in
            let components = key.split(separator: "-")
            let year = String(components[0])
            let month = String(components[1])
            return ("\(year).\(month)", events.sorted { $0.date > $1.date })
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if allEvents.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "chronicle.empty.title".localized(),
                        subtitle: "chronicle.empty.subtitle".localized()
                    )
                } else {
                    List {
                        // Year filter chips
                        if !availableYears.isEmpty {
                            Section {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        Button {
                                            selectedYear = nil
                                        } label: {
                                            Text("chronicle.filter.all".localized())
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(selectedYear == nil ? Color.pink : Color.gray.opacity(0.2))
                                                .foregroundStyle(selectedYear == nil ? .white : .primary)
                                                .clipShape(Capsule())
                                        }
                                        
                                        ForEach(availableYears, id: \.self) { year in
                                            Button {
                                                selectedYear = year
                                            } label: {
                                                Text(String(year))
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(selectedYear == year ? Color.pink : Color.gray.opacity(0.2))
                                                    .foregroundStyle(selectedYear == year ? .white : .primary)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                        
                        // Timeline events grouped by month
                        ForEach(groupedEvents, id: \.0) { monthYear, events in
                            Section {
                                ForEach(events) { event in
                                    TimelineEventRow(event: event)
                                }
                            } header: {
                                HStack {
                                    Text(monthYear)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.pink)
                                    Spacer()
                                    Text("\(events.count) \("chronicle.events".localized())")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $searchText, prompt: "chronicle.search_placeholder".localized())
            .navigationTitle("chronicle.title".localized())
        }
    }
}

struct TimelineEventRow: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(event.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: event.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(event.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text(event.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(event.date.formattedSimple())
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                // Additional info based on type
                if case .restaurant(let restaurant) = event {
                    HStack(spacing: 8) {
                        if restaurant.rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("\(restaurant.rating)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.orange)
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("\(restaurant.checkInCount)×")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.pink)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ChronicleView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
