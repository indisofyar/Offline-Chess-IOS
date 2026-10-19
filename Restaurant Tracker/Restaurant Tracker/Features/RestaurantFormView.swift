//
//  RestaurantFormView.swift
//  Restaurant Tracker
//
//  Add a new restaurant or edit an existing one.
//

import SwiftUI
import SwiftData
import MapKit

struct RestaurantFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let restaurant: Restaurant?
    private let searchRegion: MKCoordinateRegion?

    @State private var name: String
    @State private var cuisine: Cuisine
    @State private var address: String
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var rating: Int
    @State private var notes: String
    @State private var visitDate: Date

    @State private var searchQuery = ""
    @State private var searchResults: [PlaceResult] = []
    @State private var isSearching = false
    @State private var searchError: String?

    init(restaurant: Restaurant? = nil, searchRegion: MKCoordinateRegion? = nil) {
        self.restaurant = restaurant
        self.searchRegion = searchRegion
        _name = State(initialValue: restaurant?.name ?? "")
        _cuisine = State(initialValue: restaurant?.cuisine ?? .other)
        _address = State(initialValue: restaurant?.address ?? "")
        _coordinate = State(initialValue: restaurant?.coordinate)
        _rating = State(initialValue: restaurant?.rating ?? 4)
        _notes = State(initialValue: restaurant?.notes ?? "")
        _visitDate = State(initialValue: restaurant?.visitDate ?? Date())
    }

    private var isEditing: Bool { restaurant != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && coordinate != nil
    }

    var body: some View {
        Form {
            locationSection

            Section("Details") {
                TextField("Name", text: $name)
                Picker("Cuisine", selection: $cuisine) {
                    ForEach(Cuisine.allCases) { cuisine in
                        Text("\(cuisine.emoji)  \(cuisine.displayName)").tag(cuisine)
                    }
                }
                DatePicker("Visited", selection: $visitDate, in: ...Date(), displayedComponents: .date)
            }

            Section("Rating") {
                VStack(spacing: 8) {
                    StarRatingPicker(rating: $rating, size: 36)
                    Text(ratingDescription(rating))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rating(rating))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }

            Section("Notes") {
                TextField("What did you order? Would you go back?", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
        .navigationTitle(isEditing ? "Edit Restaurant" : "Add Restaurant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!canSave)
            }
        }
        .task(id: searchQuery) {
            await runSearch()
        }
    }

    // MARK: - Location

    @ViewBuilder
    private var locationSection: some View {
        if let coordinate {
            Section("Location") {
                Map(
                    initialPosition: .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)),
                    interactionModes: []
                ) {
                    Marker(name.isEmpty ? "Restaurant" : name, systemImage: "fork.knife", coordinate: coordinate)
                        .tint(Color.rating(rating))
                }
                .id("\(coordinate.latitude),\(coordinate.longitude)")
                .frame(height: 140)
                .listRowInsets(EdgeInsets())

                if !address.isEmpty {
                    Label(address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                }
                Button("Change Location", systemImage: "arrow.triangle.2.circlepath") {
                    self.coordinate = nil
                }
            }
        } else {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search for a restaurant", text: $searchQuery)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                    if isSearching {
                        ProgressView()
                    }
                }
                ForEach(searchResults) { result in
                    Button {
                        select(result)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            if !result.address.isEmpty {
                                Text(result.address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if let searchError {
                    Text(searchError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Location")
            } footer: {
                Text("Find the place on Apple Maps to pin it on your map.")
            }
        }
    }

    private func runSearch() async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            searchResults = []
            searchError = nil
            return
        }
        // Debounce typing; cancelled automatically when the query changes.
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }

        isSearching = true
        defer { isSearching = false }
        do {
            let results = try await PlaceSearch.search(query, near: searchRegion)
            guard !Task.isCancelled else { return }
            searchResults = results
            searchError = results.isEmpty ? "No places found." : nil
        } catch {
            guard !Task.isCancelled else { return }
            searchResults = []
            searchError = "No places found."
        }
    }

    private func select(_ result: PlaceResult) {
        coordinate = result.coordinate
        address = result.address
        if name.trimmingCharacters(in: .whitespaces).isEmpty || !isEditing {
            name = result.name
        }
        if cuisine == .other {
            cuisine = result.suggestedCuisine
        }
        searchQuery = ""
        searchResults = []
    }

    // MARK: - Save

    private func save() {
        guard let coordinate else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if let restaurant {
            restaurant.name = trimmedName
            restaurant.cuisine = cuisine
            restaurant.address = address
            restaurant.coordinate = coordinate
            restaurant.rating = Restaurant.clamp(rating)
            restaurant.notes = notes
            restaurant.visitDate = visitDate
        } else {
            let newRestaurant = Restaurant(
                name: trimmedName,
                cuisine: cuisine,
                address: address,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                rating: rating,
                notes: notes,
                visitDate: visitDate
            )
            modelContext.insert(newRestaurant)
        }
        dismiss()
    }
}

#Preview("Add Restaurant") {
    NavigationStack {
        RestaurantFormView()
    }
    .modelContainer(SampleData.makeContainer(empty: true))
}

#Preview("Edit Restaurant") {
    let container = SampleData.makeContainer()
    let restaurant = try! container.mainContext.fetch(FetchDescriptor<Restaurant>(sortBy: [SortDescriptor(\.name)])).first!
    NavigationStack {
        RestaurantFormView(restaurant: restaurant)
    }
    .modelContainer(container)
}
