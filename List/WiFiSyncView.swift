//
//  WiFiSyncView.swift
//  List
//
//  Created by Linyi Yan on 11/12/25.
//

import SwiftUI
import SwiftData

struct WiFiSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncManager = NetworkSyncManager()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("sync.mode".localized(), selection: $selectedTab) {
                Text("sync.mode.server".localized()).tag(0)
                Text("sync.mode.client".localized()).tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Tab Content
            TabView(selection: $selectedTab) {
                ServerView(syncManager: syncManager)
                    .tag(0)
                
                ClientView(syncManager: syncManager)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("sync.title".localized())
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            syncManager.stopServer()
        }
    }
}

// MARK: - Server View (Share Data)
struct ServerView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var syncManager: NetworkSyncManager
    @State private var copiedToClipboard = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Label("sync.server.instructions.title".localized(), systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.appAccent)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. " + "sync.server.instructions.step1".localized())
                        Text("2. " + "sync.server.instructions.step2".localized())
                        Text("3. " + "sync.server.instructions.step3".localized())
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Server Control
                VStack(spacing: 16) {
                    if syncManager.isServerRunning {
                        // IP Address Display
                        VStack(spacing: 12) {
                            Image(systemName: "wifi")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)
                            
                            Text("sync.server.ip_address".localized())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if let ipAddress = syncManager.serverIPAddress {
                                HStack(spacing: 12) {
                                    Text(ipAddress)
                                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.primary)
                                    
                                    Button {
                                        UIPasteboard.general.string = ipAddress
                                        copiedToClipboard = true
                                        
                                        // Reset after 2 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            copiedToClipboard = false
                                        }
                                    } label: {
                                        Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                                            .font(.title2)
                                            .foregroundStyle(copiedToClipboard ? .green : .appAccent)
                                    }
                                }
                                
                                if copiedToClipboard {
                                    Text("sync.copied".localized())
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                        .transition(.opacity)
                                }
                            } else {
                                Text("sync.server.getting_ip".localized())
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                ProgressView()
                            }
                            
                            Text("sync.server.port".localized() + ": \(syncManager.serverPort)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                        
                        // Status
                        if !syncManager.syncStatus.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(syncManager.syncStatus)
                                    .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Stop Button
                        Button {
                            syncManager.stopServer()
                        } label: {
                            Label("sync.server.stop".localized(), systemImage: "stop.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        
                    } else {
                        // Start Button
                        VStack(spacing: 16) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                            
                            Text("sync.server.ready".localized())
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                syncManager.startServer(modelContext: modelContext)
                            } label: {
                                Label("sync.server.start".localized(), systemImage: "play.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.appAccent)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 32)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
}

// MARK: - Client View (Import Data)
struct ClientView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var syncManager: NetworkSyncManager
    @State private var ipAddress = ""
    @State private var showingConfirmAlert = false
    @State private var showingResultAlert = false
    @State private var importResult: ImportResult?
    @State private var importError: Error?
    @FocusState private var isIPFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Label("sync.client.instructions.title".localized(), systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.appAccent)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. " + "sync.client.instructions.step1".localized())
                        Text("2. " + "sync.client.instructions.step2".localized())
                        Text("3. " + "sync.client.instructions.step3".localized())
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // IP Address Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("sync.client.enter_ip".localized())
                        .font(.headline)
                    
                    TextField("sync.client.ip_placeholder".localized(), text: $ipAddress)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 20, design: .monospaced))
                        .focused($isIPFieldFocused)
                        .disabled(syncManager.isSyncing)
                    
                    Text("sync.client.ip_example".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Warning
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("sync.client.warning.title".localized())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("sync.client.warning.message".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                // Sync Button
                Button {
                    isIPFieldFocused = false
                    showingConfirmAlert = true
                } label: {
                    HStack {
                        if syncManager.isSyncing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text("sync.client.sync_button".localized())
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ipAddress.isEmpty || syncManager.isSyncing ? Color.gray : Color.appAccent)
                    .cornerRadius(12)
                }
                .disabled(ipAddress.isEmpty || syncManager.isSyncing)
                
                // Status
                if !syncManager.syncStatus.isEmpty {
                    HStack {
                        Image(systemName: syncManager.syncStatus.contains("sync.client.success".localized()) ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(syncManager.syncStatus.contains("sync.client.success".localized()) ? .green : .blue)
                        Text(syncManager.syncStatus)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(syncManager.syncStatus.contains("sync.client.success".localized()) ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .alert("sync.client.confirm.title".localized(), isPresented: $showingConfirmAlert) {
            Button("alert.cancel".localized(), role: .cancel) { }
            Button("sync.client.confirm.button".localized(), role: .destructive) {
                performSync()
            }
        } message: {
            Text("sync.client.confirm.message".localized())
        }
        .alert(importError == nil ? "sync.client.success.title".localized() : "sync.client.error.title".localized(), isPresented: $showingResultAlert) {
            Button("alert.confirm".localized(), role: .cancel) {
                if importError == nil {
                    // Clear IP after successful sync
                    ipAddress = ""
                }
            }
        } message: {
            if let result = importResult {
                Text(String(format: "import.complete.message".localized(), 
                          result.totalImported, 
                          result.restaurants, 
                          result.beverages, 
                          result.travels, 
                          result.recreations))
            } else if let error = importError {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func performSync() {
        Task {
            do {
                let result = try await syncManager.fetchDataFromServer(
                    ipAddress: ipAddress.trimmingCharacters(in: .whitespaces),
                    modelContext: modelContext
                )
                
                await MainActor.run {
                    importResult = result
                    importError = nil
                    showingResultAlert = true
                }
            } catch {
                await MainActor.run {
                    importResult = nil
                    importError = error
                    showingResultAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WiFiSyncView()
            .modelContainer(for: Restaurant.self, inMemory: true)
    }
}
