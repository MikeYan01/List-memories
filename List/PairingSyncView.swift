//
//  PairingSyncView.swift
//  List
//
//  Created by Linyi Yan on 11/12/25.
//

import SwiftUI
import SwiftData

struct PairingSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncManager = PairingSyncManager()
    @State private var selectedMode = 0 // 0 = Share, 1 = Receive
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode Picker
            Picker("Mode", selection: $selectedMode) {
                Label("sync.share".localized(), systemImage: "square.and.arrow.up")
                    .tag(0)
                Label("sync.receive".localized(), systemImage: "square.and.arrow.down")
                    .tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            if selectedMode == 0 {
                ShareModeView(syncManager: syncManager)
            } else {
                ReceiveModeView(syncManager: syncManager)
            }
        }
        .navigationTitle("sync.title".localized())
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            syncManager.stopServer()
        }
    }
}

// MARK: - Share Mode View
struct ShareModeView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var syncManager: PairingSyncManager
    
    var body: some View {
        VStack(spacing: 32) {
            if syncManager.isServerRunning {
                // Show Pairing Code
                VStack(spacing: 24) {
                    Spacer()
                    
                    Text("sync.pairing_code".localized())
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if let code = syncManager.pairingCode {
                        Text(code)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.appAccent)
                            .tracking(8)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.appAccent.opacity(0.1))
                            )
                    }
                    
                    Text("sync.enter_code_instruction".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if !syncManager.syncStatus.isEmpty {
                        HStack {
                            Image(systemName: syncManager.syncStatus.contains("sync.data_sent".localized()) ? "checkmark.circle.fill" : "info.circle.fill")
                                .foregroundStyle(syncManager.syncStatus.contains("sync.data_sent".localized()) ? .green : .blue)
                            Text(syncManager.syncStatus)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(syncManager.syncStatus.contains("sync.data_sent".localized()) ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Button {
                        syncManager.stopServer()
                    } label: {
                        Label("sync.stop".localized(), systemImage: "stop.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
                .padding()
                
            } else {
                // Ready to Share
                VStack(spacing: 32) {
                    Spacer()
                    
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 80))
                        .foregroundStyle(.appAccent)
                    
                    VStack(spacing: 12) {
                        Text("sync.share_title".localized())
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("sync.share_subtitle".localized())
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button {
                        syncManager.startServer(modelContext: modelContext)
                    } label: {
                        Label("sync.generate_code".localized(), systemImage: "number.square")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appAccent)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

// MARK: - Receive Mode View
struct ReceiveModeView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var syncManager: PairingSyncManager
    @State private var pairingCode = ""
    @State private var showingConfirmAlert = false
    @State private var showingResultAlert = false
    @State private var importResult: ImportResult?
    @State private var importError: Error?
    @FocusState private var isCodeFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            if syncManager.isSyncing {
                // Syncing State
                VStack(spacing: 24) {
                    Spacer()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text(syncManager.syncStatus)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
                
            } else {
                // Ready to Receive
                Spacer()
                
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 80))
                    .foregroundStyle(.appAccent)
                
                VStack(spacing: 12) {
                    Text("sync.receive_title".localized())
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("sync.receive_subtitle".localized())
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    Text("sync.enter_code".localized())
                        .font(.headline)
                    
                    TextField("0000", text: $pairingCode)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .tracking(8)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .frame(width: 200)
                        .focused($isCodeFieldFocused)
                        .onChange(of: pairingCode) { _, newValue in
                            // Limit to 4 digits
                            if newValue.count > 4 {
                                pairingCode = String(newValue.prefix(4))
                            }
                            // Auto-submit when 4 digits entered
                            if pairingCode.count == 4 {
                                isCodeFieldFocused = false
                            }
                        }
                }
                
                // Warning
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("sync.warning".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                
                Button {
                    showingConfirmAlert = true
                } label: {
                    Label("sync.sync_button".localized(), systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pairingCode.count == 4 ? Color.appAccent : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(pairingCode.count != 4)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .padding()
        .alert("sync.confirm_title".localized(), isPresented: $showingConfirmAlert) {
            Button("alert.cancel".localized(), role: .cancel) { }
            Button("sync.confirm_button".localized(), role: .destructive) {
                performSync()
            }
        } message: {
            Text("sync.confirm_message".localized())
        }
        .alert(importError == nil ? "sync.success_title".localized() : "sync.error_title".localized(), isPresented: $showingResultAlert) {
            Button("alert.confirm".localized(), role: .cancel) {
                if importError == nil {
                    pairingCode = ""
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
                let result = try await syncManager.connectToServer(
                    pairingCode: pairingCode,
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
        PairingSyncView()
            .modelContainer(for: Restaurant.self, inMemory: true)
    }
}
