//
//  DataExportImport.swift
//  List
//
//  Created by Linyi Yan on 11/4/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Exportable Models
struct ExportData: Codable {
    let restaurants: [ExportRestaurant]
    let beverages: [ExportBeverage]
    let travels: [ExportTravel]
    let recreations: [ExportRecreation]
    let exportDate: Date
    let version: String
}

struct ExportRestaurant: Codable {
    let name: String
    let location: String
    let date: Date
    let rating: Int
    let notes: String
    let photos: [String] // Base64 encoded
    let tags: [String]
    let checkInCount: Int
}

struct ExportBeverage: Codable {
    let shopName: String
    let date: Date
    let rating: Int
    let notes: String
    let photos: [String] // Base64 encoded
}

struct ExportTravel: Codable {
    let destination: String
    let plannedDate: Date
    let actualStartDate: Date?
    let actualEndDate: Date?
    let notes: String
    let photos: [String] // Base64 encoded
}

struct ExportRecreation: Codable {
    let type: String
    let name: String
    let location: String
    let date: Date
    let notes: String
    let photos: [String] // Base64 encoded
}

// MARK: - Export/Import Manager
class DataManager {
    
    // MARK: - Export
    static func exportData(modelContext: ModelContext) throws -> URL {
        // Fetch all data
        let restaurantDescriptor = FetchDescriptor<Restaurant>(sortBy: [SortDescriptor(\.date)])
        let beverageDescriptor = FetchDescriptor<Beverage>(sortBy: [SortDescriptor(\.date)])
        let travelDescriptor = FetchDescriptor<Travel>(sortBy: [SortDescriptor(\.plannedDate)])
        let recreationDescriptor = FetchDescriptor<Recreation>(sortBy: [SortDescriptor(\.date)])
        
        let restaurants = try modelContext.fetch(restaurantDescriptor)
        let beverages = try modelContext.fetch(beverageDescriptor)
        let travels = try modelContext.fetch(travelDescriptor)
        let recreations = try modelContext.fetch(recreationDescriptor)
        
        // Convert to exportable format
        let exportRestaurants = restaurants.map { restaurant in
            ExportRestaurant(
                name: restaurant.name,
                location: restaurant.location,
                date: restaurant.date,
                rating: restaurant.rating,
                notes: restaurant.notes,
                photos: restaurant.photosData.map { $0.base64EncodedString() },
                tags: restaurant.tags,
                checkInCount: restaurant.checkInCount
            )
        }
        
        let exportBeverages = beverages.map { beverage in
            ExportBeverage(
                shopName: beverage.shopName,
                date: beverage.date,
                rating: beverage.rating,
                notes: beverage.notes,
                photos: beverage.photosData.map { $0.base64EncodedString() }
            )
        }
        
        let exportTravels = travels.map { travel in
            ExportTravel(
                destination: travel.destination,
                plannedDate: travel.plannedDate,
                actualStartDate: travel.actualStartDate,
                actualEndDate: travel.actualEndDate,
                notes: travel.notes,
                photos: travel.photosData.map { $0.base64EncodedString() }
            )
        }
        
        let exportRecreations = recreations.map { recreation in
            ExportRecreation(
                type: recreation.type.rawValue,
                name: recreation.name,
                location: recreation.location,
                date: recreation.date,
                notes: recreation.notes,
                photos: recreation.photosData.map { $0.base64EncodedString() }
            )
        }
        
        let exportData = ExportData(
            restaurants: exportRestaurants,
            beverages: exportBeverages,
            travels: exportTravels,
            recreations: exportRecreations,
            exportDate: Date(),
            version: "1.0"
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(exportData)
        
        // Save to temporary file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "\("export.filename_prefix".localized())_\(dateString).json"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try jsonData.write(to: tempURL)
        
        return tempURL
    }
    
    // MARK: - Import
    static func importData(from url: URL, modelContext: ModelContext, replaceExisting: Bool = false) throws -> ImportResult {
        // Read JSON file
        let jsonData = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: jsonData)
        
        var importedCount = 0
        
        // If replace existing, delete all current data
        if replaceExisting {
            try deleteAllData(modelContext: modelContext)
        }
        
        // Import restaurants
        for exportRestaurant in exportData.restaurants {
            let photosData = exportRestaurant.photos.compactMap { Data(base64Encoded: $0) }
            let restaurant = Restaurant(
                name: exportRestaurant.name,
                location: exportRestaurant.location,
                date: exportRestaurant.date,
                rating: exportRestaurant.rating,
                notes: exportRestaurant.notes,
                photosData: photosData,
                tags: exportRestaurant.tags,
                checkInCount: exportRestaurant.checkInCount
            )
            modelContext.insert(restaurant)
            importedCount += 1
        }
        
        // Import beverages
        for exportBeverage in exportData.beverages {
            let photosData = exportBeverage.photos.compactMap { Data(base64Encoded: $0) }
            let beverage = Beverage(
                shopName: exportBeverage.shopName,
                date: exportBeverage.date,
                rating: exportBeverage.rating,
                notes: exportBeverage.notes,
                photosData: photosData
            )
            modelContext.insert(beverage)
            importedCount += 1
        }
        
        // Import travels
        for exportTravel in exportData.travels {
            let photosData = exportTravel.photos.compactMap { Data(base64Encoded: $0) }
            let travel = Travel(
                destination: exportTravel.destination,
                plannedDate: exportTravel.plannedDate,
                actualStartDate: exportTravel.actualStartDate,
                actualEndDate: exportTravel.actualEndDate,
                notes: exportTravel.notes,
                photosData: photosData
            )
            modelContext.insert(travel)
            importedCount += 1
        }
        
        // Import recreations
        for exportRecreation in exportData.recreations {
            let photosData = exportRecreation.photos.compactMap { Data(base64Encoded: $0) }
            if let type = RecreationType(rawValue: exportRecreation.type) {
                let recreation = Recreation(
                    type: type,
                    name: exportRecreation.name,
                    location: exportRecreation.location,
                    date: exportRecreation.date,
                    notes: exportRecreation.notes,
                    photosData: photosData
                )
                modelContext.insert(recreation)
                importedCount += 1
            }
        }
        
        // Save context
        try modelContext.save()
        
        return ImportResult(
            totalImported: importedCount,
            restaurants: exportData.restaurants.count,
            beverages: exportData.beverages.count,
            travels: exportData.travels.count,
            recreations: exportData.recreations.count
        )
    }
    
    // MARK: - Delete All Data
    private static func deleteAllData(modelContext: ModelContext) throws {
        let restaurantDescriptor = FetchDescriptor<Restaurant>()
        let beverageDescriptor = FetchDescriptor<Beverage>()
        let travelDescriptor = FetchDescriptor<Travel>()
        let recreationDescriptor = FetchDescriptor<Recreation>()
        
        let restaurants = try modelContext.fetch(restaurantDescriptor)
        let beverages = try modelContext.fetch(beverageDescriptor)
        let travels = try modelContext.fetch(travelDescriptor)
        let recreations = try modelContext.fetch(recreationDescriptor)
        
        restaurants.forEach { modelContext.delete($0) }
        beverages.forEach { modelContext.delete($0) }
        travels.forEach { modelContext.delete($0) }
        recreations.forEach { modelContext.delete($0) }
    }
}

// MARK: - Import Result
struct ImportResult {
    let totalImported: Int
    let restaurants: Int
    let beverages: Int
    let travels: Int
    let recreations: Int
}

// MARK: - Document Type for File Picker
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
