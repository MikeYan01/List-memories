//
//  RecreationView.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import SwiftUI
import SwiftData

struct RecreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recreation.date, order: .reverse) private var recreations: [Recreation]
    @State private var showingAddSheet = false
    @State private var selectedFilter: RecreationType?
    @State private var searchText = ""
    
    var filteredRecreations: [Recreation] {
        recreations.filter { recreation in
            let matchesType = selectedFilter == nil || recreation.type == selectedFilter
            let matchesSearch = searchText.isEmpty ||
                recreation.name.localizedCaseInsensitiveContains(searchText) ||
                recreation.location.localizedCaseInsensitiveContains(searchText) ||
                recreation.notes.localizedCaseInsensitiveContains(searchText)
            
            return matchesType && matchesSearch
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if recreations.isEmpty {
                    EmptyStateView(
                        icon: "theatermasks.fill",
                        title: "还没有娱乐记录",
                        subtitle: "记录你们一起欢乐的每个瞬间"
                    )
                } else {
                    VStack(spacing: 0) {
                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterChip(
                                    title: "全部",
                                    isSelected: selectedFilter == nil,
                                    action: { selectedFilter = nil }
                                )
                                
                                ForEach(RecreationType.allCases, id: \.self) { type in
                                    FilterChip(
                                        title: type.rawValue,
                                        isSelected: selectedFilter == type,
                                        action: { selectedFilter = type }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .background(.ultraThinMaterial)
                        
                        if filteredRecreations.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "没有找到结果",
                                subtitle: "试试其他搜索词或筛选条件"
                            )
                        } else {
                            List {
                                ForEach(filteredRecreations) { recreation in
                                    NavigationLink {
                                        RecreationDetailView(recreation: recreation)
                                    } label: {
                                        RecreationRow(recreation: recreation)
                                    }
                                }
                                .onDelete(perform: deleteRecreations)
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                }
            }
            .navigationTitle("乐 🎭")
            .searchable(text: $searchText, prompt: "搜索活动名称、地点或备注")
            .toolbar {
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
                AddRecreationView()
            }
        }
    }
    
    private func deleteRecreations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredRecreations[index])
            }
        }
    }
}

struct RecreationRow: View {
    let recreation: Recreation
    
    var typeIcon: String {
        switch recreation.type {
        case .outdoor: return "figure.outdoor.cycle"
        case .movie: return "film.fill"
        case .concert: return "music.mic"
        case .game: return "gamecontroller.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo thumbnail
            if !recreation.photosData.isEmpty {
                PhotoThumbnail(photosData: recreation.photosData)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: typeIcon)
                        .foregroundStyle(.pink)
                    
                    Text(recreation.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.pink.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text(recreation.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(recreation.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if !recreation.location.isEmpty {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                        Text(recreation.location)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !recreation.notes.isEmpty {
                    Text(recreation.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecreationDetailView: View {
    let recreation: Recreation
    @State private var showingEditSheet = false
    
    var typeIcon: String {
        switch recreation.type {
        case .outdoor: return "figure.outdoor.cycle"
        case .movie: return "film.fill"
        case .concert: return "music.mic"
        case .game: return "gamecontroller.fill"
        }
    }
    
    var body: some View {
        List {
            Section {
                DetailRow(icon: typeIcon, label: "类型", value: recreation.type.rawValue)
                DetailRow(icon: "star.fill", label: "名称", value: recreation.name)
                
                if !recreation.location.isEmpty {
                    DetailRow(icon: "location.fill", label: "地点", value: recreation.location)
                }
                
                DetailRow(icon: "calendar", label: "日期", value: recreation.date.formatted(date: .long, time: .omitted))
            }
            
            // Photo carousel
            if !recreation.photosData.isEmpty {
                Section {
                    PhotoCarouselView(photosData: recreation.photosData)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
            
            if !recreation.notes.isEmpty {
                Section("备注") {
                    Text(recreation.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("娱乐详情")
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
            EditRecreationView(recreation: recreation)
        }
    }
}

struct AddRecreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var type: RecreationType = .outdoor
    @State private var name = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var photosData: [Data] = []
    
    var requiresLocation: Bool {
        type == .concert
    }
    
    var showsLocation: Bool {
        type == .concert || type == .outdoor
    }
    
    var namePlaceholder: String {
        switch type {
        case .outdoor: return "活动名称（如：迪士尼）"
        case .movie: return "电影名称"
        case .concert: return "演唱会名称"
        case .game: return "游戏名称"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("类型") {
                    Picker("选择类型", selection: $type) {
                        ForEach(RecreationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("基本信息") {
                    TextField(namePlaceholder, text: $name)
                    
                    if showsLocation {
                        TextField(requiresLocation ? "地点" : "地点（可选）", text: $location)
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                
                Section("照片") {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("备注") {
                    TextField("添加备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("添加娱乐活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRecreation()
                    }
                    .disabled(name.isEmpty || (requiresLocation && location.isEmpty))
                }
            }
        }
    }
    
    private func saveRecreation() {
        let recreation = Recreation(type: type, name: name, location: location, date: date, notes: notes, photosData: photosData)
        modelContext.insert(recreation)
        dismiss()
    }
}

struct EditRecreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let recreation: Recreation
    
    @State private var type: RecreationType = .outdoor
    @State private var name = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var photosData: [Data] = []
    
    var requiresLocation: Bool {
        type == .concert
    }
    
    var showsLocation: Bool {
        type == .concert || type == .outdoor
    }
    
    var namePlaceholder: String {
        switch type {
        case .outdoor: return "活动名称（如：迪士尼）"
        case .movie: return "电影名称"
        case .concert: return "演唱会名称"
        case .game: return "游戏名称"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("类型") {
                    Picker("选择类型", selection: $type) {
                        ForEach(RecreationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("基本信息") {
                    TextField(namePlaceholder, text: $name)
                    
                    if showsLocation {
                        TextField(requiresLocation ? "地点" : "地点（可选）", text: $location)
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                
                Section("照片") {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("备注") {
                    TextField("添加备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("编辑娱乐活动")
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
                    .disabled(name.isEmpty || (requiresLocation && location.isEmpty))
                }
            }
            .onAppear {
                type = recreation.type
                name = recreation.name
                location = recreation.location
                date = recreation.date
                notes = recreation.notes
                photosData = recreation.photosData
            }
        }
    }
    
    private func saveChanges() {
        recreation.type = type
        recreation.name = name
        recreation.location = location
        recreation.date = date
        recreation.notes = notes
        recreation.photosData = photosData
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    RecreationView()
        .modelContainer(for: Recreation.self, inMemory: true)
}
