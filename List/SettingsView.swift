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
    
    @State private var showingResetAlert = false
    @State private var showingGlobalSearch = false
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
                Section {
                    Button {
                        showingGlobalSearch = true
                    } label: {
                        Label("全局搜索", systemImage: "magnifyingglass")
                            .foregroundStyle(.pink)
                    }
                }
                
                Section("统计") {
                    StatRow(icon: "fork.knife", label: "餐厅", count: restaurants.count, color: .pink)
                    StatRow(icon: "cup.and.saucer.fill", label: "饮品", count: beverages.count, color: .orange)
                    StatRow(icon: "airplane.departure", label: "旅行", count: travels.count, color: .blue)
                    StatRow(icon: "theatermasks.fill", label: "娱乐", count: recreations.count, color: .purple)
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("总记录数")
                        Spacer()
                        Text("\(totalRecords)")
                            .fontWeight(.semibold)
                    }
                }
                
                Section("数据管理") {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Label("导出数据", systemImage: "square.and.arrow.up")
                            if isExporting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(totalRecords == 0 || isExporting)
                    
                    Button {
                        showingImportPicker = true
                    } label: {
                        HStack {
                            Label("导入数据", systemImage: "square.and.arrow.down")
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
                        Label("清空所有数据", systemImage: "trash.fill")
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .alert("清空所有数据", isPresented: $showingResetAlert) {
                Button("取消", role: .cancel) { }
                Button("确认清空", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("此操作将删除所有记录，无法恢复。确定要继续吗？")
            }
            .sheet(isPresented: $showingGlobalSearch) {
                GlobalSearchView()
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
            .alert("导入完成", isPresented: $showingImportAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                if let result = importResult {
                    Text("成功导入 \(result.totalImported) 条记录\n餐厅: \(result.restaurants)\n饮品: \(result.beverages)\n旅行: \(result.travels)\n娱乐: \(result.recreations)")
                } else if let error = importError {
                    Text("导入失败: \(error.localizedDescription)")
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
                                .foregroundStyle(.pink)
                            VStack(alignment: .leading) {
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                Text("JSON 文件")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Toggle("替换现有数据", isOn: $replaceExisting)
                } footer: {
                    if replaceExisting {
                        Text("将删除所有现有数据并导入新数据")
                            .foregroundStyle(.red)
                    } else {
                        Text("新数据将添加到现有数据中")
                    }
                }
            }
            .navigationTitle("导入选项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") {
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
