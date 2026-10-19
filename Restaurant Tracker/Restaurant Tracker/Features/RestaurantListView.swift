//
//  RestaurantListView.swift
//  Restaurant Tracker
//

import SwiftUI
import SwiftData

enum RestaurantSort: String, CaseIterable, Identifiable {
    case recent = "Most Recent"
    case rating = "Highest Rated"
    case name = "Name"

    var id: String { rawValue }
}

struct RestaurantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var restaurants: [Restaurant]

    @State private var sort: RestaurantSort = .recent
    @State private var searchText = ""
    @State private var showingAddRestaurant = false

    private var displayedRestaurants: [Restaurant] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let matching = query.isEmpty ? restaurants : restaurants.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.cuisine.displayName.localizedCaseInsensitiveContains(query)
                || $0.address.localizedCaseInsensitiveContains(query)
        }
        switch sort {
        case .recent:
            return matching.sorted { $0.visitDate > $1.visitDate }
        case .rating:
            return matching.sorted { ($0.rating, $0.visitDate) > ($1.rating, $1.visitDate) }
        case .name:
            return matching.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }

    private var averageRating: Double {
        guard !restaurants.isEmpty else { return 0 }
        return Double(restaurants.reduce(0) { $0 + $1.rating }) / Double(restaurants.count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if restaurants.isEmpty {
                    ContentUnavailableView {
                        Label("No Restaurants Yet", systemImage: "fork.knife")
                    } description: {
                        Text("Add the places you've eaten and give them a rating.")
                    } actions: {
                        Button("Add Restaurant") { showingAddRestaurant = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    list
                }
            }
            .navigationTitle("Visited")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(RestaurantSort.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddRestaurant = true
                    } label: {
                        Label("Add Restaurant", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRestaurant) {
                NavigationStack {
                    RestaurantFormView()
                }
            }
        }
    }

    private var list: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    StatTile(icon: "fork.knife", title: "Visited", value: "\(restaurants.count)", color: .orange)
                    StatTile(icon: "star.fill", title: "Average", value: averageRating.formatted(.number.precision(.fractionLength(1))), color: .starYellow)
                    StatTile(icon: "crown.fill", title: "5 Stars", value: "\(restaurants.filter { $0.rating == 5 }.count)", color: .green)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section(sort.rawValue) {
                ForEach(displayedRestaurants) { restaurant in
                    NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                    } label: {
                        RestaurantRow(restaurant: restaurant)
                    }
                }
                .onDelete { offsets in
                    let toDelete = offsets.map { displayedRestaurants[$0] }
                    for restaurant in toDelete {
                        modelContext.delete(restaurant)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search name, cuisine or area")
    }
}

struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            CuisineIcon(cuisine: restaurant.cuisine)
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(1)
                StarRatingView(rating: restaurant.rating, size: 12)
                Text("\(restaurant.cuisine.displayName) · \(restaurant.visitDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview("Visited List") {
    RestaurantListView()
        .modelContainer(SampleData.container)
}

#Preview("Visited List Empty") {
    RestaurantListView()
        .modelContainer(SampleData.emptyContainer)
}
