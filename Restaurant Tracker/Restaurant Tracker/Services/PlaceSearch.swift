//
//  PlaceSearch.swift
//  Restaurant Tracker
//

import Foundation
import MapKit

struct PlaceResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let suggestedCuisine: Cuisine
}

enum PlaceSearch {
    /// Searches Apple Maps for food & drink places matching `query`, optionally biased to `region`.
    static func search(_ query: String, near region: MKCoordinateRegion? = nil) async throws -> [PlaceResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .restaurant, .cafe, .bakery, .brewery, .winery, .foodMarket, .nightlife,
        ])
        if let region {
            request.region = region
        }

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.map { item in
            PlaceResult(
                name: item.name ?? "Unknown place",
                address: formattedAddress(item.placemark),
                coordinate: item.placemark.coordinate,
                suggestedCuisine: cuisine(for: item.pointOfInterestCategory)
            )
        }
    }

    private static func formattedAddress(_ placemark: MKPlacemark) -> String {
        let street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        return [street, placemark.locality ?? "", placemark.postalCode ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private static func cuisine(for category: MKPointOfInterestCategory?) -> Cuisine {
        switch category {
        case .some(.cafe): return .cafe
        case .some(.bakery): return .bakery
        case .some(.brewery), .some(.winery), .some(.nightlife): return .bar
        default: return .other
        }
    }
}
