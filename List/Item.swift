//
//  Item.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import Foundation
import SwiftData

// 吃 - Restaurant records
@Model
final class Restaurant {
    var name: String
    var location: String
    var date: Date
    var rating: Int  // 0-10 points
    var notes: String
    @Attribute(.externalStorage) var photosData: [Data]
    var tags: [String]  // Custom tags like "Japanese", "Italian", "Spicy", etc.
    
    init(name: String, location: String, date: Date, rating: Int = 0, notes: String = "", photosData: [Data] = [], tags: [String] = []) {
        self.name = name
        self.location = location
        self.date = date
        self.rating = rating
        self.notes = notes
        self.photosData = photosData
        self.tags = tags
    }
}

// 喝 - Beverage records
@Model
final class Beverage {
    var shopName: String
    var date: Date
    var rating: Int  // 0-10 points
    var notes: String
    @Attribute(.externalStorage) var photosData: [Data]
    
    init(shopName: String, date: Date, rating: Int = 0, notes: String = "", photosData: [Data] = []) {
        self.shopName = shopName
        self.date = date
        self.rating = rating
        self.notes = notes
        self.photosData = photosData
    }
}

// 玩 - Travel records
@Model
final class Travel {
    var destination: String
    var plannedDate: Date
    var actualDate: Date?
    var notes: String
    @Attribute(.externalStorage) var photosData: [Data]
    
    init(destination: String, plannedDate: Date, actualDate: Date? = nil, notes: String = "", photosData: [Data] = []) {
        self.destination = destination
        self.plannedDate = plannedDate
        self.actualDate = actualDate
        self.notes = notes
        self.photosData = photosData
    }
}

// 乐 - Recreation records
enum RecreationType: String, Codable, CaseIterable {
    case outdoor = "outdoor"
    case movie = "movie"
    case concert = "concert"
    case game = "game"
    
    var localizedName: String {
        switch self {
        case .outdoor: return "recreation.type.outdoor".localized()
        case .movie: return "recreation.type.movie".localized()
        case .concert: return "recreation.type.concert".localized()
        case .game: return "recreation.type.game".localized()
        }
    }
    
    // Custom decoder to support legacy Chinese values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Try to decode from new English values first
        if let value = RecreationType(rawValue: rawValue) {
            self = value
            return
        }
        
        // Fall back to legacy Chinese values
        switch rawValue {
        case "户外活动":
            self = .outdoor
        case "电影":
            self = .movie
        case "演唱会":
            self = .concert
        case "游戏":
            self = .game
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot initialize RecreationType from invalid String value \(rawValue)"
                )
            )
        }
    }
}

@Model
final class Recreation {
    var type: RecreationType
    var name: String
    var location: String
    var date: Date
    var notes: String
    @Attribute(.externalStorage) var photosData: [Data]
    
    init(type: RecreationType, name: String, location: String = "", date: Date, notes: String = "", photosData: [Data] = []) {
        self.type = type
        self.name = name
        self.location = location
        self.date = date
        self.notes = notes
        self.photosData = photosData
    }
}
