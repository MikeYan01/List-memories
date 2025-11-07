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
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var showingFilterSheet = false
    
    enum StatusFilter: String, CaseIterable {
        case all = "all"
        case planned = "planned"
        case completed = "completed"
        
        var localizedName: String {
            switch self {
            case .all: return "travel.filter.all".localized()
            case .planned: return "travel.filter.planned".localized()
            case .completed: return "travel.filter.completed".localized()
            }
        }
        
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
                        title: "travel.empty.title".localized(),
                        subtitle: "travel.empty.subtitle".localized()
                    )
                } else {
                    VStack(spacing: 0) {
                        // Filter chips
                        if selectedStatusFilter != .all {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(
                                        title: selectedStatusFilter.localizedName,
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
                                title: "common.search.empty.title".localized(),
                                subtitle: "common.search.empty.subtitle".localized()
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
            .navigationTitle("travel.title".localized())
            .searchable(text: $searchText, prompt: "travel.search_placeholder".localized())
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
                Section("travel.filter.section".localized()) {
                    ForEach(TravelView.StatusFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedStatus = filter
                            dismiss()
                        } label: {
                            HStack {
                                Text(filter.localizedName)
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
            .navigationTitle("travel.filter.title".localized())
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
                        Text(displayDate.formattedSimple())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if isPlanned {
                            Text("travel.status.planned".localized())
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
                DetailRow(icon: "mappin.and.ellipse", label: "travel.detail.destination".localized(), value: travel.destination)
                DetailRow(icon: "calendar", label: "travel.detail.planned_date".localized(), value: travel.plannedDate.formattedSimple())
                
                if let actualDate = travel.actualDate {
                    DetailRow(icon: "checkmark.circle.fill", label: "travel.detail.actual_date".localized(), value: actualDate.formattedSimple())
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("travel.detail.status".localized())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("travel.status.planned".localized())
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
                Section("travel.detail.notes".localized()) {
                    Text(travel.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("travel.detail.title".localized())
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
                Section("travel.section.basic_info".localized()) {
                    TextField("travel.destination_placeholder".localized(), text: $destination)
                    DatePicker("travel.planned_date_label".localized(), selection: $plannedDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                }
                
                Section {
                    Toggle("travel.completed_toggle".localized(), isOn: $hasActualDate)
                    
                    if hasActualDate {
                        DatePicker("travel.actual_date_label".localized(), selection: $actualDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                    }
                }
                
                Section("travel.section.photos".localized()) {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("travel.section.notes".localized()) {
                    TextField("travel.notes_placeholder".localized(), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("travel.add.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized()) {
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
                Section("travel.section.basic_info".localized()) {
                    TextField("travel.destination_placeholder".localized(), text: $destination)
                    DatePicker("travel.planned_date_label".localized(), selection: $plannedDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                }
                
                Section {
                    Toggle("travel.completed_toggle".localized(), isOn: $hasActualDate)
                    
                    if hasActualDate {
                        DatePicker("travel.actual_date_label".localized(), selection: $actualDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                    }
                }
                
                Section("travel.section.photos".localized()) {
                    MultiplePhotosPickerView(photosData: $photosData)
                }
                
                Section("travel.section.notes".localized()) {
                    TextField("travel.notes_placeholder".localized(), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("travel.edit.title".localized())
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
