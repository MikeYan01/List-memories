//
//  TravelView.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import SwiftUI
import SwiftData

struct TravelView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Travel.plannedDate, order: .reverse) private var travels: [Travel]
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var showingFilterSheet = false
    
    enum StatusFilter: String, CaseIterable {
        case all = "全部"
        case planned = "计划中"
        case completed = "已完成"
        
        func matches(_ travel: Travel) -> Bool {
            switch self {
            case .all: return true
            case .planned: return travel.actualDate == nil
            case .completed: return travel.actualDate != nil
            }
        }
    }
    
    var filteredTravels: [Travel] {
        travels.filter { travel in
            let matchesSearch = searchText.isEmpty ||
                travel.destination.localizedCaseInsensitiveContains(searchText) ||
                travel.notes.localizedCaseInsensitiveContains(searchText)
            
            let matchesStatus = selectedStatusFilter.matches(travel)
            
            return matchesSearch && matchesStatus
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if travels.isEmpty {
                    EmptyStateView(
                        icon: "airplane.departure",
                        title: "还没有旅行记录",
                        subtitle: "记录你们一起探索的每个地方"
                    )
                } else {
                    VStack(spacing: 0) {
                        // Filter chips
                        if selectedStatusFilter != .all {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(
                                        title: selectedStatusFilter.rawValue,
                                        isSelected: true
                                    ) {
                                        selectedStatusFilter = .all
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .background(.ultraThinMaterial)
                        }
                        
                        if filteredTravels.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "没有找到结果",
                                subtitle: "试试其他搜索词或筛选条件"
                            )
                        } else {
                            List {
                                ForEach(filteredTravels) { travel in
                                    NavigationLink {
                                        TravelDetailView(travel: travel)
                                    } label: {
                                        TravelRow(travel: travel)
                                    }
                                }
                                .onDelete(perform: deleteTravels)
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                }
            }
            .navigationTitle("玩 ✈️")
            .searchable(text: $searchText, prompt: "搜索目的地或备注")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: selectedStatusFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
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
                AddTravelView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                TravelFilterView(selectedStatus: $selectedStatusFilter)
            }
        }
    }
    
    private func deleteTravels(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let travel = filteredTravels[index]
                modelContext.delete(travel)
            }
        }
    }
}

// Filter view for travel status selection
struct TravelFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStatus: TravelView.StatusFilter
    
    var body: some View {
        NavigationStack {
            List {
                Section("按状态筛选") {
                    ForEach(TravelView.StatusFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedStatus = filter
                            dismiss()
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedStatus == filter {
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

struct TravelRow: View {
    let travel: Travel
    
    var displayDate: Date {
        travel.actualDate ?? travel.plannedDate
    }
    
    var isPlanned: Bool {
        travel.actualDate == nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo thumbnail
            if !travel.photosData.isEmpty {
                PhotoThumbnail(photosData: travel.photosData)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(travel.destination)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(displayDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if isPlanned {
                            Text("计划中")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                if !travel.notes.isEmpty {
                    Text(travel.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TravelDetailView: View {
    let travel: Travel
    @State private var showingEditSheet = false
    
    var displayDate: Date {
        travel.actualDate ?? travel.plannedDate
    }
    
    var isPlanned: Bool {
        travel.actualDate == nil
    }
    
    var body: some View {
        List {
            Section {
                DetailRow(icon: "mappin.and.ellipse", label: "目的地", value: travel.destination)
                DetailRow(icon: "calendar", label: "计划日期", value: travel.plannedDate.formatted(date: .long, time: .omitted))
                
                if let actualDate = travel.actualDate {
                    DetailRow(icon: "checkmark.circle.fill", label: "实际日期", value: actualDate.formatted(date: .long, time: .omitted))
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("状态")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("计划中")
                                .font(.body)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Photo carousel
            if !travel.photosData.isEmpty {
                Section {
                    PhotoCarouselView(photosData: travel.photosData)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
            
            if !travel.notes.isEmpty {
                Section("备注") {
                    Text(travel.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("旅行详情")
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
            EditTravelView(travel: travel)
        }
    }
}

struct AddTravelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var destination = ""
    @State private var plannedDate = Date()
    @State private var hasActualDate = false
    @State private var actualDate = Date()
    @State private var notes = ""
    @State private var photosData: [Data] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("目的地", text: $destination)
                    DatePicker("计划日期", selection: $plannedDate, displayedComponents: .date)
                }
                
                Section {
                    Toggle("已完成旅行", isOn: $hasActualDate)
                    
                    if hasActualDate {
                        DatePicker("实际日期", selection: $actualDate, displayedComponents: .date)
                    }
                }
                
                Section("照片") {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("备注") {
                    TextField("添加备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("添加旅行")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTravel()
                    }
                    .disabled(destination.isEmpty)
                }
            }
        }
    }
    
    private func saveTravel() {
        let travel = Travel(
            destination: destination,
            plannedDate: plannedDate,
            actualDate: hasActualDate ? actualDate : nil,
            notes: notes,
            photosData: photosData
        )
        modelContext.insert(travel)
        dismiss()
    }
}

struct EditTravelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let travel: Travel
    
    @State private var destination = ""
    @State private var plannedDate = Date()
    @State private var hasActualDate = false
    @State private var actualDate = Date()
    @State private var notes = ""
    @State private var photosData: [Data] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("目的地", text: $destination)
                    DatePicker("计划日期", selection: $plannedDate, displayedComponents: .date)
                }
                
                Section {
                    Toggle("已完成旅行", isOn: $hasActualDate)
                    
                    if hasActualDate {
                        DatePicker("实际日期", selection: $actualDate, displayedComponents: .date)
                    }
                }
                
                Section("照片") {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("备注") {
                    TextField("添加备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("编辑旅行")
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
                    .disabled(destination.isEmpty)
                }
            }
            .onAppear {
                destination = travel.destination
                plannedDate = travel.plannedDate
                hasActualDate = travel.actualDate != nil
                actualDate = travel.actualDate ?? Date()
                notes = travel.notes
                photosData = travel.photosData
            }
        }
    }
    
    private func saveChanges() {
        travel.destination = destination
        travel.plannedDate = plannedDate
        travel.actualDate = hasActualDate ? actualDate : nil
        travel.notes = notes
        travel.photosData = photosData
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    TravelView()
        .modelContainer(for: Travel.self, inMemory: true)
}
