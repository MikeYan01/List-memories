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
                        title: "还没有饮品记录",
                        subtitle: "记录你们一起品尝的每一杯"
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
                        
                        if filteredBeverages.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "没有找到结果",
                                subtitle: "试试其他搜索词或筛选条件"
                            )
                        } else {
                            List {
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
                }
            }
            .navigationTitle("喝 🥤")
            .searchable(text: $searchText, prompt: "搜索店名或备注")
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
                Section("按评分筛选") {
                    ForEach(BeverageView.RatingFilter.allCases, id: \.self) { filter in
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

struct BeverageRow: View {
    let beverage: Beverage
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo thumbnail
            if !beverage.photosData.isEmpty {
                PhotoThumbnail(photosData: beverage.photosData)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(beverage.shopName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(beverage.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if beverage.rating > 0 {
                    StarRatingView(rating: beverage.rating)
                }
                
                if !beverage.notes.isEmpty {
                    Text(beverage.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct BeverageDetailView: View {
    let beverage: Beverage
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            Section {
                DetailRow(icon: "wineglass", label: "店名", value: beverage.shopName)
                DetailRow(icon: "calendar", label: "日期", value: beverage.date.formatted(date: .long, time: .omitted))
                
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
                Section("备注") {
                    Text(beverage.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("饮品详情")
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
                Section("基本信息") {
                    TextField("店名", text: $shopName)
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
            .navigationTitle("添加饮品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
                Section("基本信息") {
                    TextField("店名", text: $shopName)
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
            .navigationTitle("编辑饮品")
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
    BeverageView()
        .modelContainer(for: Beverage.self, inMemory: true)
}
