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
    @ObservedObject var localizationManager = LocalizationManager.shared
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
                        title: "recreation.empty.title".localized(),
                        subtitle: "recreation.empty.subtitle".localized()
                    )
                } else {
                    VStack(spacing: 0) {
                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                Button {
                                    selectedFilter = nil
                                } label: {
                                    Text("recreation.filter.all".localized())
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedFilter == nil ? Color.pink : Color.gray.opacity(0.2))
                                        .foregroundStyle(selectedFilter == nil ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                
                                ForEach(RecreationType.allCases, id: \.self) { type in
                                    Button {
                                        selectedFilter = type
                                    } label: {
                                        Text(type.localizedName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedFilter == type ? Color.pink : Color.gray.opacity(0.2))
                                            .foregroundStyle(selectedFilter == type ? .white : .primary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .background(.ultraThinMaterial)
                        
                        if filteredRecreations.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "common.search.empty.title".localized(),
                                subtitle: "common.search.empty.subtitle".localized()
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
            .navigationTitle("recreation.title".localized())
            .searchable(text: $searchText, prompt: "recreation.search_placeholder".localized())
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
        VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: typeIcon)
                        .foregroundStyle(.pink)
                    
                    Text(recreation.type.localizedName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.pink.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text(recreation.date.formattedSimple())
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
                DetailRow(icon: typeIcon, label: "recreation.detail.type".localized(), value: recreation.type.localizedName)
                DetailRow(icon: "star.fill", label: "recreation.detail.name".localized(), value: recreation.name)
                
                if !recreation.location.isEmpty {
                    DetailRow(icon: "location.fill", label: "recreation.detail.location".localized(), value: recreation.location)
                }
                
                DetailRow(icon: "calendar", label: "recreation.detail.date".localized(), value: recreation.date.formattedSimple())
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
                Section("recreation.detail.notes".localized()) {
                    Text(recreation.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("recreation.detail.title".localized())
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
                Section("recreation.section.type".localized()) {
                    Picker("recreation.type_picker".localized(), selection: $type) {
                        ForEach(RecreationType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("recreation.section.basic_info".localized()) {
                    TextField(namePlaceholder, text: $name)
                    
                    if showsLocation {
                        TextField(requiresLocation ? "recreation.location_required".localized() : "recreation.location_optional".localized(), text: $location)
                    }
                    
                    DatePicker("recreation.date_label".localized(), selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                }
                
                Section("recreation.section.photos".localized()) {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("recreation.section.notes".localized()) {
                    TextField("recreation.notes_placeholder".localized(), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("recreation.add.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized()) {
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
        case .outdoor: return "recreation.name_placeholder.outdoor".localized()
        case .movie: return "recreation.name_placeholder.movie".localized()
        case .concert: return "recreation.name_placeholder.concert".localized()
        case .game: return "recreation.name_placeholder.game".localized()
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("recreation.section.type".localized()) {
                    Picker("recreation.type_picker".localized(), selection: $type) {
                        ForEach(RecreationType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("recreation.section.basic_info".localized()) {
                    TextField(namePlaceholder, text: $name)
                    
                    if showsLocation {
                        TextField(requiresLocation ? "recreation.location_required".localized() : "recreation.location_optional".localized(), text: $location)
                    }
                    
                    DatePicker("recreation.date_label".localized(), selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                }
                
                Section("recreation.section.photos".localized()) {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("recreation.section.notes".localized()) {
                    TextField("recreation.notes_placeholder".localized(), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("recreation.edit.title".localized())
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
