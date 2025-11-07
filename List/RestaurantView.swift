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
    @State private var selectedTag: String?
    
    // Get all unique tags from restaurants
    var allTags: [String] {
        let tagSet = Set(restaurants.flatMap { $0.tags })
        return Array(tagSet).sorted()
    }
    
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
                restaurant.notes.localizedCaseInsensitiveContains(searchText) ||
                restaurant.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            
            let matchesRating = selectedRatingFilter.matches(restaurant.rating)
            
            let matchesTag = selectedTag == nil || restaurant.tags.contains(selectedTag!)
            
            return matchesSearch && matchesRating && matchesTag
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
                        if selectedRatingFilter != .all || selectedTag != nil {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    if selectedRatingFilter != .all {
                                        FilterChip(
                                            title: selectedRatingFilter.localizedName,
                                            isSelected: true
                                        ) {
                                            selectedRatingFilter = .all
                                        }
                                    }
                                    
                                    if let tag = selectedTag {
                                        FilterChip(
                                            title: tag,
                                            isSelected: true
                                        ) {
                                            selectedTag = nil
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .background(.ultraThinMaterial)
                        }
                        
                        // Tag chips for quick filtering
                        if !allTags.isEmpty && selectedTag == nil {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(allTags, id: \.self) { tag in
                                        FilterChip(
                                            title: tag,
                                            isSelected: false
                                        ) {
                                            selectedTag = tag
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .background(Color(.systemGroupedBackground))
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
                
                // Display tags
                if !restaurant.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(restaurant.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.pink.opacity(0.15))
                                    .foregroundStyle(.pink)
                                    .clipShape(Capsule())
                            }
                        }
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
                
                // Display tags
                if !restaurant.tags.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(.pink)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("restaurant.tags".localized())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            FlowLayout(spacing: 6) {
                                ForEach(restaurant.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.pink.opacity(0.15))
                                        .foregroundStyle(.pink)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
    @State private var tags: [String] = []
    @State private var newTagText = ""
    
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
                
                Section("restaurant.section.tags".localized()) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Display existing tags
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.subheadline)
                                        Button {
                                            tags.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.pink.opacity(0.15))
                                    .foregroundStyle(.pink)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        
                        // Add new tag
                        HStack {
                            TextField("restaurant.add_tag_placeholder".localized(), text: $newTagText)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .onSubmit {
                                    addTag()
                                }
                            
                            if !newTagText.isEmpty {
                                Button(action: {
                                    addTag()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.pink)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
        let restaurant = Restaurant(name: name, location: location, date: date, rating: rating, notes: notes, photosData: photosData, tags: tags)
        modelContext.insert(restaurant)
        dismiss()
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTagText = ""
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
    @State private var tags: [String] = []
    @State private var newTagText = ""
    
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
                
                Section("restaurant.section.tags".localized()) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Display existing tags
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.subheadline)
                                        Button {
                                            tags.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.pink.opacity(0.15))
                                    .foregroundStyle(.pink)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        
                        // Add new tag
                        HStack {
                            TextField("restaurant.add_tag_placeholder".localized(), text: $newTagText)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .onSubmit {
                                    addTag()
                                }
                            
                            if !newTagText.isEmpty {
                                Button(action: {
                                    addTag()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.pink)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
                tags = restaurant.tags
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
        restaurant.tags = tags
        try? modelContext.save()
        dismiss()
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTagText = ""
    }
}

#Preview {
    RestaurantView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
