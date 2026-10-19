//
//  Restaurant.swift
//  Restaurant Tracker
//

import Foundation
import SwiftData
import CoreLocation

@Model
class Restaurant {
    var id: UUID
    var name: String
    var cuisineRaw: String
    var address: String
    var latitude: Double
    var longitude: Double
    var rating: Int // 1...5 stars
    var notes: String
    var visitDate: Date
    var createdAt: Date

    init(
        name: String,
        cuisine: Cuisine = .other,
        address: String = "",
        latitude: Double,
        longitude: Double,
        rating: Int = 3,
        notes: String = "",
        visitDate: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.cuisineRaw = cuisine.rawValue
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.rating = Restaurant.clamp(rating)
        self.notes = notes
        self.visitDate = visitDate
        self.createdAt = Date()
    }

    var cuisine: Cuisine {
        get { Cuisine(rawValue: cuisineRaw) ?? .other }
        set { cuisineRaw = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        get { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }

    static func clamp(_ rating: Int) -> Int {
        min(max(rating, 1), 5)
    }
}
