//
//  ContentView.swift
//  Restaurant Tracker
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map.fill") {
                RestaurantMapView()
            }
            Tab("Visited", systemImage: "list.star") {
                RestaurantListView()
            }
        }
    }
}

#Preview("Content") {
    ContentView()
        .modelContainer(SampleData.container)
}

#Preview("Content Dark") {
    ContentView()
        .modelContainer(SampleData.container)
        .preferredColorScheme(.dark)
}
