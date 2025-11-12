//
//  PairingSyncManager.swift
//  List
//
//  Created by Linyi Yan on 11/12/25.
//

import Combine
import Foundation
import Network
import SwiftData
import SwiftUI

@MainActor
class PairingSyncManager: ObservableObject {
    @Published var isServerRunning = false
    @Published var pairingCode: String?
    @Published var syncStatus: String = ""
    @Published var isSyncing = false
    
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var modelContext: ModelContext?
    private let serverPort: UInt16 = 8080
    
    init() {}
    
    // MARK: - Generate 4-Digit Pairing Code
    private func generatePairingCode() -> String {
        String(format: "%04d", Int.random(in: 0...9999))
    }
    
    // MARK: - Start Server with Pairing Code
    func startServer(modelContext: ModelContext) {
        guard !isServerRunning else { return }
        
        self.modelContext = modelContext
        self.pairingCode = generatePairingCode()
        
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
                            self?.syncStatus = "sync.server.ready".localized()
                        case .failed(let error):
                            self?.isServerRunning = false
                            self?.syncStatus = "sync.error".localized() + ": \(error.localizedDescription)"
                        case .cancelled:
                            self?.isServerRunning = false
                            self?.pairingCode = nil
                            self?.syncStatus = ""
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
                    self.syncStatus = "sync.error".localized() + ": \(error.localizedDescription)"
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
        pairingCode = nil
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
                // Parse request path
                if request.contains("GET /verify/") {
                    // Verification endpoint - returns server IP if pairing code matches
                    let components = request.components(separatedBy: "/verify/")
                    if components.count > 1 {
                        let codePart = components[1].components(separatedBy: " ")[0]
                        if codePart == self.pairingCode {
                            // Valid pairing code - send server IP
                            self.sendIPResponse(on: connection)
                        } else {
                            // Invalid pairing code
                            self.sendUnauthorizedResponse(on: connection)
                        }
                    }
                } else if request.contains("GET /sync") {
                    // Data download endpoint
                    self.sendDataResponse(on: connection)
                } else {
                    self.sendNotFoundResponse(on: connection)
                }
            }
        }
    }
    
    // MARK: - Send IP Response
    private func sendIPResponse(on connection: NWConnection) {
        guard let serverIP = getLocalIPAddress() else {
            sendErrorResponse(on: connection, message: "Could not determine server IP")
            return
        }
        
        let jsonResponse = "{\"ip\":\"\(serverIP)\"}"
        let response = """
        HTTP/1.1 200 OK\r
        Content-Type: application/json\r
        Content-Length: \(jsonResponse.count)\r
        Access-Control-Allow-Origin: *\r
        \r
        \(jsonResponse)
        """
        
        guard let data = response.data(using: .utf8) else {
            connection.cancel()
            return
        }
        
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
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
                    self.syncStatus = "sync.data_sent".localized()
                }
                
            } catch {
                await MainActor.run {
                    self.sendErrorResponse(on: connection, message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Send Unauthorized Response
    private func sendUnauthorizedResponse(on connection: NWConnection) {
        let message = "Invalid pairing code"
        let response = """
        HTTP/1.1 401 Unauthorized\r
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
    
    // MARK: - Connect to Server with Pairing Code
    func connectToServer(pairingCode: String, modelContext: ModelContext) async throws -> ImportResult {
        isSyncing = true
        syncStatus = "sync.searching".localized()
        
        defer {
            Task { @MainActor in
                isSyncing = false
            }
        }
        
        // Scan local network for servers and get server IP
        let localIP = await findServerOnNetwork(pairingCode: pairingCode)
        
        guard let serverIP = localIP else {
            await MainActor.run {
                syncStatus = "sync.server_not_found".localized()
            }
            throw SyncError.serverNotFound
        }
        
        // Build URL for data download (no pairing code needed in URL now)
        let urlString = "http://\(serverIP):\(serverPort)/sync"
        guard let url = URL(string: urlString) else {
            throw SyncError.invalidURL
        }
        
        await MainActor.run {
            syncStatus = "sync.downloading".localized()
        }
        
        // Fetch data
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyncError.serverError
        }
        
        guard httpResponse.statusCode == 200 else {
            await MainActor.run {
                syncStatus = "sync.error".localized()
            }
            throw SyncError.serverError
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("pairing_sync.json")
        try data.write(to: tempURL)
        
        await MainActor.run {
            syncStatus = "sync.importing".localized()
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
            syncStatus = "sync.complete".localized()
        }
        
        return result
    }
    
    // MARK: - Find Server on Local Network
    private func findServerOnNetwork(pairingCode: String) async -> String? {
        // Get local IP to determine subnet
        guard let localIP = getLocalIPAddress() else { return nil }
        
        // Extract subnet (e.g., 192.168.1.x)
        let components = localIP.split(separator: ".")
        guard components.count == 4 else { return nil }
        
        let subnet = "\(components[0]).\(components[1]).\(components[2])"
        
        await MainActor.run {
            syncStatus = "sync.scanning_network".localized()
        }
        
        // Try common router IPs first, then scan subnet
        let priorityIPs = ["1", "100", "101", "102"]
        let allIPs = (1...254).map { String($0) }
        let orderedIPs = priorityIPs + allIPs.filter { !priorityIPs.contains($0) }
        
        // Try IPs in parallel batches
        for batch in stride(from: 0, to: orderedIPs.count, by: 20) {
            let batchIPs = orderedIPs[batch..<min(batch + 20, orderedIPs.count)]
            
            let results = await withTaskGroup(of: String?.self, returning: String?.self) { group in
                for lastOctet in batchIPs {
                    let ip = "\(subnet).\(lastOctet)"
                    group.addTask {
                        await self.tryConnect(to: ip, pairingCode: pairingCode)
                    }
                }
                
                for await result in group {
                    if let foundIP = result {
                        return foundIP
                    }
                }
                return nil
            }
            
            if let foundIP = results {
                return foundIP
            }
        }
        
        return nil
    }
    
    // MARK: - Try Connect to IP
    private func tryConnect(to ip: String, pairingCode: String) async -> String? {
        let urlString = "http://\(ip):\(serverPort)/verify/\(pairingCode)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 0.5 // Quick timeout
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                // Valid pairing code - parse server IP from response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let serverIP = json["ip"] {
                    return serverIP
                }
            }
        } catch {
            // Connection failed, try next IP
        }
        
        return nil
    }
    
    // MARK: - Get Local IP Address
    private func getLocalIPAddress() -> String? {
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
}

// MARK: - Sync Errors
enum SyncError: LocalizedError {
    case invalidPairingCode
    case invalidURL
    case serverError
    case serverNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidPairingCode:
            return "sync.invalid_code".localized()
        case .invalidURL:
            return "sync.error.invalid_url".localized()
        case .serverError:
            return "sync.error.server".localized()
        case .serverNotFound:
            return "sync.server_not_found".localized()
        }
    }
}
