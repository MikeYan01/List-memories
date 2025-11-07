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
    @Binding var showChronicle: Bool
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
                } else if filteredRestaurants.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "common.search.empty.title".localized(),
                        subtitle: "common.search.empty.subtitle".localized()
                    )
                } else {
                    List {
                        // Filter chips section
                        if selectedRatingFilter != .all || selectedTag != nil {
                            Section {
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
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                        
                        // Tag chips for quick filtering
                        if !allTags.isEmpty && selectedTag == nil && searchText.isEmpty {
                            Section {
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
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                        
                        // Restaurant list
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
            .searchable(text: $searchText, prompt: "restaurant.search_placeholder".localized())
            .navigationTitle("restaurant.title".localized())
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
                        showChronicle = true
                    } label: {
                        Image(systemName: "book.fill")
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
        VStack(alignment: .leading, spacing: 10) {
            // Header: Name and Date
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    // Check-in count badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text(String(format: "restaurant.detail.times_visited".localized(), restaurant.checkInCount))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.pink.opacity(0.15))
                    .foregroundStyle(.pink)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Text(restaurant.date.formattedSimple())
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            // Location
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.pink.opacity(0.8))
                Text(restaurant.location)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Rating
            if restaurant.rating > 0 {
                StarRatingView(rating: restaurant.rating)
            }
            
            // Notes preview
            if !restaurant.notes.isEmpty {
                Text(restaurant.notes)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            
            // Tags
            if !restaurant.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(restaurant.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    LinearGradient(
                                        colors: [Color.pink.opacity(0.1), Color.pink.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundStyle(.pink)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
    }
}

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @Environment(\.modelContext) private var modelContext
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
                
                // Check-in count row
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.pink)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("restaurant.detail.checkin_count".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "restaurant.detail.times_visited".localized(), restaurant.checkInCount))
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Decrease button
                        Button {
                            withAnimation {
                                if restaurant.checkInCount > 0 {
                                    restaurant.checkInCount -= 1
                                    try? modelContext.save()
                                }
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(restaurant.checkInCount > 0 ? .pink : .gray.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .disabled(restaurant.checkInCount == 0)
                        
                        // Increase button
                        Button {
                            withAnimation {
                                restaurant.checkInCount += 1
                                try? modelContext.save()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("restaurant.detail.checkin_button".localized())
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [Color.pink.opacity(0.8), Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                
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
    @State private var checkInCount = 1
    
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
                
                Section("restaurant.detail.checkin_count".localized()) {
                    HStack {
                        Text(String(format: "restaurant.detail.times_visited".localized(), checkInCount))
                            .font(.body)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // Decrease button
                            Button {
                                if checkInCount > 0 {
                                    checkInCount -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(checkInCount > 0 ? .pink : .gray.opacity(0.5))
                            }
                            .buttonStyle(.borderless)
                            .disabled(checkInCount == 0)
                            
                            // Increase button
                            Button {
                                checkInCount += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.pink)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
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
                checkInCount = restaurant.checkInCount
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
        restaurant.checkInCount = checkInCount
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
    RestaurantView(showChronicle: .constant(false))
        .modelContainer(for: Restaurant.self, inMemory: true)
}
