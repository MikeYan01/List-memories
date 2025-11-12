//
//  NetworkSyncManager.swift
//  List
//
//  Created by Linyi Yan on 11/12/25.
//

import Combine
import Foundation
import Network
import SwiftData

@MainActor
class NetworkSyncManager: ObservableObject {
    @Published var isServerRunning = false
    @Published var serverIPAddress: String?
    @Published var serverPort: UInt16 = 8080
    @Published var syncStatus: String = ""
    @Published var isSyncing = false
    
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var modelContext: ModelContext?
    
    init() {}
    
    // MARK: - Get Local IP Address
    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // WiFi interface
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                              socklen_t(interface.ifa_addr.pointee.sa_len),
                              &hostname,
                              socklen_t(hostname.count),
                              nil,
                              socklen_t(0),
                              NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address
    }
    
    // MARK: - Start Server
    func startServer(modelContext: ModelContext) {
        guard !isServerRunning else { return }
        
        self.modelContext = modelContext
        
        Task {
            do {
                let parameters = NWParameters.tcp
                parameters.allowLocalEndpointReuse = true
                
                let listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: serverPort))
                self.listener = listener
                
                listener.stateUpdateHandler = { [weak self] state in
                    Task { @MainActor [weak self] in
                        switch state {
                        case .ready:
                            self?.isServerRunning = true
                            self?.serverIPAddress = self?.getLocalIPAddress()
                            self?.syncStatus = "sync.server.running".localized()
                        case .failed(let error):
                            self?.isServerRunning = false
                            self?.syncStatus = "sync.server.error".localized() + ": \(error.localizedDescription)"
                        case .cancelled:
                            self?.isServerRunning = false
                            self?.syncStatus = "sync.server.stopped".localized()
                        default:
                            break
                        }
                    }
                }
                
                listener.newConnectionHandler = { [weak self] connection in
                    Task { @MainActor [weak self] in
                        self?.handleConnection(connection)
                    }
                }
                
                listener.start(queue: .main)
                
            } catch {
                await MainActor.run {
                    self.syncStatus = "sync.server.error".localized() + ": \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Stop Server
    func stopServer() {
        listener?.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
        isServerRunning = false
        serverIPAddress = nil
        syncStatus = ""
    }
    
    // MARK: - Handle Connection
    private func handleConnection(_ connection: NWConnection) {
        connections.append(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                Task { @MainActor [weak self] in
                    self?.receiveRequest(on: connection)
                }
            }
        }
        
        connection.start(queue: .main)
    }
    
    // MARK: - Receive HTTP Request
    private func receiveRequest(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            
            Task { @MainActor in
                // Check if it's a GET request for /data
                if request.contains("GET /data") {
                    self.sendDataResponse(on: connection)
                } else {
                    self.sendNotFoundResponse(on: connection)
                }
            }
        }
    }
    
    // MARK: - Send Data Response
    private func sendDataResponse(on connection: NWConnection) {
        guard let modelContext = modelContext else {
            sendErrorResponse(on: connection, message: "Model context not available")
            return
        }
        
        Task {
            do {
                // Export data using existing DataManager
                let exportURL = try DataManager.exportData(modelContext: modelContext)
                let jsonData = try Data(contentsOf: exportURL)
                
                // Clean up temp file
                try? FileManager.default.removeItem(at: exportURL)
                
                // Build HTTP response
                let response = """
                HTTP/1.1 200 OK\r
                Content-Type: application/json\r
                Content-Length: \(jsonData.count)\r
                Access-Control-Allow-Origin: *\r
                \r
                
                """
                
                guard let responseData = response.data(using: .utf8) else {
                    sendErrorResponse(on: connection, message: "Failed to build response")
                    return
                }
                
                // Send response header + JSON data
                var fullResponse = responseData
                fullResponse.append(jsonData)
                
                connection.send(content: fullResponse, completion: .contentProcessed { error in
                    if let error = error {
                        print("Send error: \(error)")
                    }
                    connection.cancel()
                })
                
                await MainActor.run {
                    self.syncStatus = "sync.server.data_sent".localized()
                }
                
            } catch {
                await MainActor.run {
                    self.sendErrorResponse(on: connection, message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Send Error Response
    private func sendErrorResponse(on connection: NWConnection, message: String) {
        let response = """
        HTTP/1.1 500 Internal Server Error\r
        Content-Type: text/plain\r
        Content-Length: \(message.count)\r
        \r
        \(message)
        """
        
        guard let data = response.data(using: .utf8) else {
            connection.cancel()
            return
        }
        
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    // MARK: - Send Not Found Response
    private func sendNotFoundResponse(on connection: NWConnection) {
        let message = "Not Found"
        let response = """
        HTTP/1.1 404 Not Found\r
        Content-Type: text/plain\r
        Content-Length: \(message.count)\r
        \r
        \(message)
        """
        
        guard let data = response.data(using: .utf8) else {
            connection.cancel()
            return
        }
        
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    // MARK: - Fetch Data from Server (Client Side)
    func fetchDataFromServer(ipAddress: String, modelContext: ModelContext) async throws -> ImportResult {
        isSyncing = true
        syncStatus = "sync.client.connecting".localized()
        
        defer {
            Task { @MainActor in
                isSyncing = false
            }
        }
        
        // Validate IP address format
        guard isValidIPAddress(ipAddress) else {
            await MainActor.run {
                syncStatus = "sync.client.invalid_ip".localized()
            }
            throw SyncError.invalidIPAddress
        }
        
        // Build URL
        let urlString = "http://\(ipAddress):\(serverPort)/data"
        guard let url = URL(string: urlString) else {
            throw SyncError.invalidURL
        }
        
        await MainActor.run {
            syncStatus = "sync.client.downloading".localized()
        }
        
        // Fetch data
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            await MainActor.run {
                syncStatus = "sync.client.error".localized()
            }
            throw SyncError.serverError
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("wifi_sync.json")
        try data.write(to: tempURL)
        
        await MainActor.run {
            syncStatus = "sync.client.importing".localized()
        }
        
        // Import data (replace existing)
        let result = try DataManager.importData(
            from: tempURL,
            modelContext: modelContext,
            replaceExisting: true
        )
        
        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
        
        await MainActor.run {
            syncStatus = "sync.client.success".localized()
        }
        
        return result
    }
    
    // MARK: - Validate IP Address
    private func isValidIPAddress(_ ipAddress: String) -> Bool {
        let parts = ipAddress.split(separator: ".")
        guard parts.count == 4 else { return false }
        
        for part in parts {
            guard let number = Int(part), number >= 0 && number <= 255 else {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Sync Errors
enum SyncError: LocalizedError {
    case invalidIPAddress
    case invalidURL
    case serverError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidIPAddress:
            return "sync.error.invalid_ip".localized()
        case .invalidURL:
            return "sync.error.invalid_url".localized()
        case .serverError:
            return "sync.error.server".localized()
        case .networkError:
            return "sync.error.network".localized()
        }
    }
}
