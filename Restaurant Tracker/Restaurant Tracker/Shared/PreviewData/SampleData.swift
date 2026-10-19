//
//  SampleData.swift
//  Restaurant Tracker
//
//  Sample restaurants used by #Preview blocks (and therefore by the snapshot tests).
//  Dates are fixed so snapshots stay stable between runs.
//

import Foundation
import SwiftData

enum SampleData {
    static func date(_ day: Int, _ month: Int, _ year: Int = 2026) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: day, hour: 19)) ?? .distantPast
    }

    static var restaurants: [Restaurant] {
        [
            Restaurant(name: "Dishoom Covent Garden", cuisine: .indian, address: "12 Upper St Martin's Ln, London",
                       latitude: 51.5124, longitude: -0.1268, rating: 5,
                       notes: "Black daal is unreal. Book ahead or queue early.", visitDate: date(12, 9)),
            Restaurant(name: "Padella", cuisine: .italian, address: "6 Southwark St, London",
                       latitude: 51.5055, longitude: -0.0910, rating: 5,
                       notes: "Pici cacio e pepe. Worth the wait.", visitDate: date(28, 8)),
            Restaurant(name: "Kanada-Ya", cuisine: .japanese, address: "64 St Giles High St, London",
                       latitude: 51.5146, longitude: -0.1272, rating: 4,
                       notes: "Rich tonkotsu, small space.", visitDate: date(3, 10)),
            Restaurant(name: "Monmouth Coffee", cuisine: .cafe, address: "2 Park St, London",
                       latitude: 51.5050, longitude: -0.0913, rating: 4, visitDate: date(14, 7)),
            Restaurant(name: "The Patty Shack", cuisine: .american, address: "Soho, London",
                       latitude: 51.5136, longitude: -0.1340, rating: 3,
                       notes: "Decent burger, fries were cold.", visitDate: date(21, 6)),
            Restaurant(name: "Corner Noodle Bar", cuisine: .thai, address: "Shoreditch, London",
                       latitude: 51.5245, longitude: -0.0780, rating: 2, visitDate: date(2, 5)),
        ]
    }

    static func makeContainer(empty: Bool = false) -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Restaurant.self, configurations: config)
        if !empty {
            for restaurant in restaurants {
                container.mainContext.insert(restaurant)
            }
        }
        return container
    }
}
