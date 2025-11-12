//
//  SettingsView.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var restaurants: [Restaurant]
    @Query private var beverages: [Beverage]
    @Query private var travels: [Travel]
    @Query private var recreations: [Recreation]
    
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showingResetAlert = false
    @State private var showingExportShare = false
    @State private var showingImportPicker = false
    @State private var showingImportOptions = false
    @State private var showingImportAlert = false
    @State private var exportURL: URL?
    @State private var importURL: URL?
    @State private var importResult: ImportResult?
    @State private var importError: Error?
    @State private var replaceExisting = false
    @State private var isExporting = false
    @State private var isImporting = false
    
    var totalRecords: Int {
        restaurants.count + beverages.count + travels.count + recreations.count
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("settings.appearance".localized()) {
                    Picker("settings.theme".localized(), selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Accent Color Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("settings.accent_color".localized())
                            .font(.body)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                            ForEach(AccentColor.allCases) { color in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        themeManager.accentColor = color
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(color.color)
                                                .frame(width: 44, height: 44)
                                            
                                            if themeManager.accentColor == color {
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: 3)
                                                    .frame(width: 44, height: 44)
                                                
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        
                                        Text(color.displayName)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("settings.language".localized()) {
                    Picker("settings.app_language".localized(), selection: $localizationManager.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("settings.statistics".localized()) {
                    StatRow(icon: "fork.knife", label: "settings.restaurant".localized(), count: restaurants.count, color: .appAccent)
                    StatRow(icon: "cup.and.saucer.fill", label: "settings.beverage".localized(), count: beverages.count, color: .orange)
                    StatRow(icon: "airplane.departure", label: "settings.travel".localized(), count: travels.count, color: .blue)
                    StatRow(icon: "theatermasks.fill", label: "settings.recreation".localized(), count: recreations.count, color: .purple)
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("settings.total_records".localized())
                        Spacer()
                        Text("\(totalRecords)")
                            .fontWeight(.semibold)
                    }
                }
                
                Section("settings.data_management".localized()) {
                    // Pairing Sync
                    NavigationLink {
                        PairingSyncView()
                    } label: {
                        Label("settings.pairing_sync".localized(), systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    // File Export
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Label("settings.export_data".localized(), systemImage: "square.and.arrow.up")
                            if isExporting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(totalRecords == 0 || isExporting)
                    
                    // File Import
                    Button {
                        showingImportPicker = true
                    } label: {
                        HStack {
                            Label("settings.import_data".localized(), systemImage: "square.and.arrow.down")
                            if isImporting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isImporting)
                    
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("settings.clear_all_data".localized(), systemImage: "trash.fill")
                    }
                }
            }
            .navigationTitle("settings.title".localized())
            .alert("alert.clear_data.title".localized(), isPresented: $showingResetAlert) {
                Button("alert.cancel".localized(), role: .cancel) { }
                Button("alert.clear_data.confirm".localized(), role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("alert.clear_data.message".localized())
            }
            .sheet(isPresented: $showingImportOptions) {
                ImportOptionsView(
                    importURL: $importURL,
                    replaceExisting: $replaceExisting,
                    onImport: { performImport() }
                )
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importURL = url
                        showingImportOptions = true
                    }
                case .failure(let error):
                    print("Error selecting file: \(error)")
                }
            }
            .sheet(item: $exportURL) { url in
                ShareSheet(items: [url])
            }
            .alert("import.complete.title".localized(), isPresented: $showingImportAlert) {
                Button("alert.confirm".localized(), role: .cancel) { }
            } message: {
                if let result = importResult {
                    Text(String(format: "import.complete.message".localized(), result.totalImported, result.restaurants, result.beverages, result.travels, result.recreations))
                } else if let error = importError {
                    Text(String(format: "import.error.message".localized(), error.localizedDescription))
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        Task {
            do {
                let url = try DataManager.exportData(modelContext: modelContext)
                await MainActor.run {
                    exportURL = url
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    print("Export error: \(error)")
                    isExporting = false
                }
            }
        }
    }
    
    private func performImport() {
        guard let url = importURL else { return }
        
        isImporting = true
        Task {
            do {
                // Start accessing security-scoped resource
                let _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                
                let result = try DataManager.importData(
                    from: url,
                    modelContext: modelContext,
                    replaceExisting: replaceExisting
                )
                
                await MainActor.run {
                    importResult = result
                    importError = nil
                    showingImportAlert = true
                    isImporting = false
                    importURL = nil
                }
            } catch {
                await MainActor.run {
                    importResult = nil
                    importError = error
                    showingImportAlert = true
                    isImporting = false
                    importURL = nil
                }
            }
        }
    }

    private func clearAllData() {
        // Delete all restaurants
        for restaurant in restaurants {
            modelContext.delete(restaurant)
        }
        
        // Delete all beverages
        for beverage in beverages {
            modelContext.delete(beverage)
        }
        
        // Delete all travels
        for travel in travels {
            modelContext.delete(travel)
        }
        
        // Delete all recreations
        for recreation in recreations {
            modelContext.delete(recreation)
        }
        
        try? modelContext.save()
    }
}

// Import Options Sheet
struct ImportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var importURL: URL?
    @Binding var replaceExisting: Bool
    let onImport: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let url = importURL {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(.appAccent)
                            VStack(alignment: .leading) {
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                Text("import.file_type".localized())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Toggle("import.replace_existing".localized(), isOn: $replaceExisting)
                } footer: {
                    if replaceExisting {
                        Text("import.replace_footer_warning".localized())
                            .foregroundStyle(.red)
                    } else {
                        Text("import.add_footer".localized())
                    }
                }
            }
            .navigationTitle("import.title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("alert.cancel".localized()) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("import.button".localized()) {
                        dismiss()
                        onImport()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// Share Sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Make URL identifiable for sheet presentation
extension URL: @retroactive Identifiable {
    public var id: String {
        self.absoluteString
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Restaurant.self, inMemory: true)
}
