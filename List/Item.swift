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
    
    init(name: String, location: String, date: Date, rating: Int = 0, notes: String = "", photosData: [Data] = []) {
        self.name = name
        self.location = location
        self.date = date
        self.rating = rating
        self.notes = notes
        self.photosData = photosData
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
    case outdoor = "户外活动"
    case movie = "电影"
    case concert = "演唱会"
    case game = "游戏"
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
