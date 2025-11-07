//
//  RestaurantView.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import SwiftUI
import SwiftData

struct RestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Restaurant.date, order: .reverse) private var restaurants: [Restaurant]
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedRatingFilter: RatingFilter = .all
    @State private var showingFilterSheet = false
    
    enum RatingFilter: String, CaseIterable {
        case all = "all"
        case highRated = "high"
        case mediumRated = "medium"
        case lowRated = "low"
        case unrated = "unrated"
        
        var localizedName: String {
            switch self {
            case .all: return "restaurant.filter.all".localized()
            case .highRated: return "restaurant.filter.high".localized()
            case .mediumRated: return "restaurant.filter.medium".localized()
            case .lowRated: return "restaurant.filter.low".localized()
            case .unrated: return "restaurant.filter.unrated".localized()
            }
        }
        
        func matches(_ rating: Int) -> Bool {
            switch self {
            case .all: return true
            case .highRated: return rating >= 8 && rating <= 10
            case .mediumRated: return rating >= 5 && rating <= 7
            case .lowRated: return rating >= 1 && rating <= 4
            case .unrated: return rating == 0
            }
        }
    }
    
    var filteredRestaurants: [Restaurant] {
        restaurants.filter { restaurant in
            let matchesSearch = searchText.isEmpty ||
                restaurant.name.localizedCaseInsensitiveContains(searchText) ||
                restaurant.location.localizedCaseInsensitiveContains(searchText) ||
                restaurant.notes.localizedCaseInsensitiveContains(searchText)
            
            let matchesRating = selectedRatingFilter.matches(restaurant.rating)
            
            return matchesSearch && matchesRating
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if restaurants.isEmpty {
                    EmptyStateView(
                        icon: "fork.knife",
                        title: "restaurant.empty.title".localized(),
                        subtitle: "restaurant.empty.subtitle".localized()
                    )
                } else {
                    VStack(spacing: 0) {
                        // Filter chips
                        if selectedRatingFilter != .all {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(
                                        title: selectedRatingFilter.localizedName,
                                        isSelected: true
                                    ) {
                                        selectedRatingFilter = .all
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .background(.ultraThinMaterial)
                        }
                        
                        if filteredRestaurants.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "common.search.empty.title".localized(),
                                subtitle: "common.search.empty.subtitle".localized()
                            )
                        } else {
                            List {
                                ForEach(filteredRestaurants) { restaurant in
                                    NavigationLink {
                                        RestaurantDetailView(restaurant: restaurant)
                                    } label: {
                                        RestaurantRow(restaurant: restaurant)
                                    }
                                }
                                .onDelete(perform: deleteRestaurants)
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                }
            }
            .navigationTitle("restaurant.title".localized())
            .searchable(text: $searchText, prompt: "restaurant.search_placeholder".localized())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: selectedRatingFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .foregroundStyle(.pink)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.pink)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRestaurantView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(selectedRating: $selectedRatingFilter)
            }
        }
    }
    
    private func deleteRestaurants(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let restaurant = filteredRestaurants[index]
                modelContext.delete(restaurant)
            }
        }
    }
}

// Filter view for rating selection
struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedRating: RestaurantView.RatingFilter
    
    var body: some View {
        NavigationStack {
            List {
                Section("restaurant.filter.section".localized()) {
                    ForEach(RestaurantView.RatingFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedRating = filter
                            dismiss()
                        } label: {
                            HStack {
                                Text(filter.localizedName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedRating == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.pink)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("restaurant.filter.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done".localized()) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RestaurantRow: View {
    let restaurant: Restaurant
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo thumbnail
            if !restaurant.photosData.isEmpty {
                PhotoThumbnail(photosData: restaurant.photosData)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(restaurant.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(restaurant.date.formattedSimple())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.pink)
                    Text(restaurant.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if restaurant.rating > 0 {
                    StarRatingView(rating: restaurant.rating)
                }
                
                if !restaurant.notes.isEmpty {
                    Text(restaurant.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            Section {
                DetailRow(icon: "fork.knife", label: "restaurant.detail.name".localized(), value: restaurant.name)
                DetailRow(icon: "location.fill", label: "restaurant.detail.location".localized(), value: restaurant.location)
                DetailRow(icon: "calendar", label: "restaurant.detail.date".localized(), value: restaurant.date.formattedSimple())
                
                if restaurant.rating > 0 {
                    RatingRow(rating: restaurant.rating)
                }
            }
            
            // Photo carousel
            if !restaurant.photosData.isEmpty {
                Section {
                    PhotoCarouselView(photosData: restaurant.photosData)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
            
            if !restaurant.notes.isEmpty {
                Section("restaurant.detail.notes".localized()) {
                    Text(restaurant.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("restaurant.detail.title".localized())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("common.edit".localized())
                        .foregroundStyle(.pink)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRestaurantView(restaurant: restaurant)
        }
    }
}

struct AddRestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var rating = 0
    @State private var notes = ""
    @State private var photosData: [Data] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("restaurant.section.basic_info".localized()) {
                    TextField("restaurant.name_placeholder".localized(), text: $name)
                    TextField("restaurant.location_placeholder".localized(), text: $location)
                    DatePicker("restaurant.date_label".localized(), selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                }
                
                Section("restaurant.section.photos".localized()) {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("restaurant.section.rating".localized()) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("restaurant.rating_prompt".localized())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        RatingPicker(rating: $rating)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("restaurant.section.notes".localized()) {
                    TextField("restaurant.notes_placeholder".localized(), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("restaurant.add.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized()) {
                        saveRestaurant()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func saveRestaurant() {
        let restaurant = Restaurant(name: name, location: location, date: date, rating: rating, notes: notes, photosData: photosData)
        modelContext.insert(restaurant)
        dismiss()
    }
}

struct EditRestaurantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let restaurant: Restaurant
    
    @State private var name = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var rating = 0
    @State private var notes = ""
    @State private var photosData: [Data] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("restaurant.section.basic_info".localized()) {
                    TextField("restaurant.name_placeholder".localized(), text: $name)
                    TextField("restaurant.location_placeholder".localized(), text: $location)
                    DatePicker("restaurant.date_label".localized(), selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                }
                
                Section("restaurant.section.photos".localized()) {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("restaurant.section.rating".localized()) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("restaurant.rating_prompt".localized())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        RatingPicker(rating: $rating)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("restaurant.section.notes".localized()) {
                    TextField("restaurant.notes_placeholder".localized(), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("restaurant.edit.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized()) {
                        saveChanges()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
            .onAppear {
                name = restaurant.name
                location = restaurant.location
                date = restaurant.date
                rating = restaurant.rating
                notes = restaurant.notes
                photosData = restaurant.photosData
            }
        }
    }
    
    private func saveChanges() {
        restaurant.name = name
        restaurant.location = location
        restaurant.date = date
        restaurant.rating = rating
        restaurant.notes = notes
        restaurant.photosData = photosData
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    RestaurantView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
