//
//  BeverageView.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import SwiftUI
import SwiftData

struct BeverageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Beverage.date, order: .reverse) private var beverages: [Beverage]
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var showChronicle: Bool
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
            case .all: return "beverage.filter.all".localized()
            case .highRated: return "beverage.filter.high".localized()
            case .mediumRated: return "beverage.filter.medium".localized()
            case .lowRated: return "beverage.filter.low".localized()
            case .unrated: return "beverage.filter.unrated".localized()
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
    
    var filteredBeverages: [Beverage] {
        beverages.filter { beverage in
            let matchesSearch = searchText.isEmpty ||
                beverage.shopName.localizedCaseInsensitiveContains(searchText) ||
                beverage.notes.localizedCaseInsensitiveContains(searchText)
            
            let matchesRating = selectedRatingFilter.matches(beverage.rating)
            
            return matchesSearch && matchesRating
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if beverages.isEmpty {
                    EmptyStateView(
                        icon: "wineglass",
                        title: "beverage.empty.title".localized(),
                        subtitle: "beverage.empty.subtitle".localized()
                    )
                } else if filteredBeverages.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "common.search.empty.title".localized(),
                        subtitle: "common.search.empty.subtitle".localized()
                    )
                } else {
                    List {
                        // Filter chips
                        if selectedRatingFilter != .all {
                            Section {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        FilterChip(
                                            title: selectedRatingFilter.localizedName,
                                            isSelected: true
                                        ) {
                                            selectedRatingFilter = .all
                                        }
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                        
                        // Beverage list
                        ForEach(filteredBeverages) { beverage in
                            NavigationLink {
                                BeverageDetailView(beverage: beverage)
                            } label: {
                                BeverageRow(beverage: beverage)
                            }
                        }
                        .onDelete(perform: deleteBeverages)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $searchText, prompt: "beverage.search_placeholder".localized())
            .navigationTitle("beverage.title".localized())
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
                AddBeverageView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                BeverageFilterView(selectedRating: $selectedRatingFilter)
            }
        }
    }
    
    private func deleteBeverages(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let beverage = filteredBeverages[index]
                modelContext.delete(beverage)
            }
        }
    }
}

// Filter view for beverage rating selection
struct BeverageFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedRating: BeverageView.RatingFilter
    
    var body: some View {
        NavigationStack {
            List {
                Section("beverage.filter.section".localized()) {
                    ForEach(BeverageView.RatingFilter.allCases, id: \.self) { filter in
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
            .navigationTitle("beverage.filter.title".localized())
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

struct BeverageRow: View {
    let beverage: Beverage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Shop name and Date
            HStack(alignment: .top) {
                Text(beverage.shopName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Spacer()
                
                Text(beverage.date.formattedSimple())
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            // Rating
            if beverage.rating > 0 {
                StarRatingView(rating: beverage.rating)
            }
            
            // Notes preview
            if !beverage.notes.isEmpty {
                Text(beverage.notes)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
    }
}

struct BeverageDetailView: View {
    let beverage: Beverage
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            Section {
                DetailRow(icon: "wineglass", label: "beverage.detail.shop_name".localized(), value: beverage.shopName)
                DetailRow(icon: "calendar", label: "beverage.detail.date".localized(), value: beverage.date.formattedSimple())
                
                if beverage.rating > 0 {
                    RatingRow(rating: beverage.rating)
                }
            }
            
            // Photo carousel
            if !beverage.photosData.isEmpty {
                Section {
                    PhotoCarouselView(photosData: beverage.photosData)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
            
            if !beverage.notes.isEmpty {
                Section("beverage.detail.notes".localized()) {
                    Text(beverage.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("beverage.detail.title".localized())
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
            EditBeverageView(beverage: beverage)
        }
    }
}

struct AddBeverageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var shopName = ""
    @State private var date = Date()
    @State private var rating = 0
    @State private var notes = ""
    @State private var photosData: [Data] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("beverage.section.basic_info".localized()) {
                    TextField("beverage.shop_name_placeholder".localized(), text: $shopName)
                    DatePicker("beverage.date_label".localized(), selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                }
                
                Section("beverage.section.photos".localized()) {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("beverage.section.rating".localized()) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("beverage.rating_prompt".localized())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        RatingPicker(rating: $rating)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("beverage.section.notes".localized()) {
                    TextField("beverage.notes_placeholder".localized(), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("beverage.add.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized()) {
                        saveBeverage()
                    }
                    .disabled(shopName.isEmpty)
                }
            }
        }
    }
    
    private func saveBeverage() {
        let beverage = Beverage(shopName: shopName, date: date, rating: rating, notes: notes, photosData: photosData)
        modelContext.insert(beverage)
        dismiss()
    }
}

struct EditBeverageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let beverage: Beverage
    
    @State private var shopName = ""
    @State private var date = Date()
    @State private var rating = 0
    @State private var notes = ""
    @State private var photosData: [Data] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("beverage.section.basic_info".localized()) {
                    TextField("beverage.shop_name_placeholder".localized(), text: $shopName)
                    DatePicker("beverage.date_label".localized(), selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                }
                
                Section("beverage.section.photos".localized()) {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("beverage.section.rating".localized()) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("beverage.rating_prompt".localized())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        RatingPicker(rating: $rating)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("beverage.section.notes".localized()) {
                    TextField("beverage.notes_placeholder".localized(), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("beverage.edit.title".localized())
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
                    .disabled(shopName.isEmpty)
                }
            }
            .onAppear {
                shopName = beverage.shopName
                date = beverage.date
                rating = beverage.rating
                notes = beverage.notes
                photosData = beverage.photosData
            }
        }
    }
    
    private func saveChanges() {
        beverage.shopName = shopName
        beverage.date = date
        beverage.rating = rating
        beverage.notes = notes
        beverage.photosData = photosData
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    BeverageView(showChronicle: .constant(false))
        .modelContainer(for: Beverage.self, inMemory: true)
}
