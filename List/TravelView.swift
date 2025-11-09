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
    @Binding var showChronicle: Bool
    @State private var showingAddSheet = false
    
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
                    List {
                        ForEach(travels) { travel in
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
            .navigationTitle("travel.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
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
                AddTravelView()
            }
        }
    }
    
    private func deleteTravels(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let travel = travels[index]
                modelContext.delete(travel)
            }
        }
    }
}

struct TravelRow: View {
    let travel: Travel
    
    var dateRangeText: String {
        if let actualStart = travel.actualStartDate, let actualEnd = travel.actualEndDate {
            // Show actual date range
            return "\(actualStart.formattedSimple()) - \(actualEnd.formattedSimple())"
        } else {
            // Show planned date only
            return travel.plannedDate.formattedSimple()
        }
    }
    
    var isPlanned: Bool {
        travel.actualStartDate == nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Destination and Date Range
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(travel.destination)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    // Status badge
                    if isPlanned {
                        Text("travel.status.planned".localized())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.8), Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                    } else {
                        Text("travel.status.completed".localized())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.8), Color.green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                Text(dateRangeText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            
            // Notes preview
            if !travel.notes.isEmpty {
                Text(travel.notes)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TravelDetailView: View {
    let travel: Travel
    @State private var showingEditSheet = false
    
    var isPlanned: Bool {
        travel.actualStartDate == nil
    }
    
    var body: some View {
        List {
            Section {
                DetailRow(icon: "mappin.and.ellipse", label: "travel.detail.destination".localized(), value: travel.destination)
                DetailRow(icon: "calendar", label: "travel.detail.planned_date".localized(), value: travel.plannedDate.formattedSimple())
                
                if let actualStart = travel.actualStartDate, let actualEnd = travel.actualEndDate {
                    DetailRow(icon: "checkmark.circle.fill", label: "travel.detail.actual_date".localized(), value: "\(actualStart.formattedSimple()) - \(actualEnd.formattedSimple())")
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
    @State private var actualStartDate = Date()
    @State private var actualEndDate = Date()
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
                        DatePicker("travel.actual_start_date_label".localized(), selection: $actualStartDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                        DatePicker("travel.actual_end_date_label".localized(), selection: $actualEndDate, displayedComponents: .date)
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
            actualStartDate: hasActualDate ? actualStartDate : nil,
            actualEndDate: hasActualDate ? actualEndDate : nil,
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
    @State private var actualStartDate = Date()
    @State private var actualEndDate = Date()
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
                        DatePicker("travel.actual_start_date_label".localized(), selection: $actualStartDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue))
                        DatePicker("travel.actual_end_date_label".localized(), selection: $actualEndDate, displayedComponents: .date)
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
                _ = ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.pink)
                    }
                }
                destination = travel.destination
                plannedDate = travel.plannedDate
                hasActualDate = travel.actualStartDate != nil
                actualStartDate = travel.actualStartDate ?? Date()
                actualEndDate = travel.actualEndDate ?? Date()
                notes = travel.notes
                photosData = travel.photosData
            }
        }
    }
    
    private func saveChanges() {
        travel.destination = destination
        travel.plannedDate = plannedDate
        travel.actualStartDate = hasActualDate ? actualStartDate : nil
        travel.actualEndDate = hasActualDate ? actualEndDate : nil
        travel.notes = notes
        travel.photosData = photosData
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    TravelView(showChronicle: .constant(false))
        .modelContainer(for: Travel.self, inMemory: true)
}
