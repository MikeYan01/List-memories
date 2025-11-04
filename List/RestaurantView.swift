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
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedRatingFilter: RatingFilter = .all
    @State private var showingFilterSheet = false
    
    enum RatingFilter: String, CaseIterable {
        case all = "全部"
        case highRated = "高分 (8-10分)"
        case mediumRated = "中等 (5-7分)"
        case lowRated = "低分 (1-4分)"
        case unrated = "未评分"
        
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
                        title: "还没有美食记录",
                        subtitle: "记录你们一起享用的每一餐"
                    )
                } else {
                    VStack(spacing: 0) {
                        // Filter chips
                        if selectedRatingFilter != .all {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(
                                        title: selectedRatingFilter.rawValue,
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
                                title: "没有找到结果",
                                subtitle: "试试其他搜索词或筛选条件"
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
            .navigationTitle("吃 🍽️")
            .searchable(text: $searchText, prompt: "搜索餐厅、地点或备注")
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
                Section("按评分筛选") {
                    ForEach(RestaurantView.RatingFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedRating = filter
                            dismiss()
                        } label: {
                            HStack {
                                Text(filter.rawValue)
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
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
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
                    
                    Text(restaurant.date, style: .date)
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
                DetailRow(icon: "fork.knife", label: "餐厅名称", value: restaurant.name)
                DetailRow(icon: "location.fill", label: "地点", value: restaurant.location)
                DetailRow(icon: "calendar", label: "日期", value: restaurant.date.formatted(date: .long, time: .omitted))
                
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
                Section("备注") {
                    Text(restaurant.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("餐厅详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("编辑")
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
                Section("基本信息") {
                    TextField("餐厅名称", text: $name)
                    TextField("地点", text: $location)
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                
                Section("照片") {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("评分") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("选择评分 (1-10分)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        RatingPicker(rating: $rating)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("备注") {
                    TextField("添加备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("添加餐厅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
                Section("基本信息") {
                    TextField("餐厅名称", text: $name)
                    TextField("地点", text: $location)
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                
                Section("照片") {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("评分") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("选择评分 (1-10分)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        RatingPicker(rating: $rating)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("备注") {
                    TextField("添加备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("编辑餐厅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
