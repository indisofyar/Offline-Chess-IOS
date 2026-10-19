//
//  RestaurantDetailView.swift
//  Restaurant Tracker
//

import SwiftUI
import SwiftData
import MapKit

struct RestaurantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var restaurant: Restaurant

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                ratingCard
                if !restaurant.notes.isEmpty {
                    notesCard
                }
                locationCard
                directionsButton
            }
            .padding()
        }
        .background(Color.appWindowBackground)
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showingEdit = true }
                    Button("Delete", systemImage: "trash", role: .destructive) { showingDeleteConfirmation = true }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                RestaurantFormView(restaurant: restaurant)
            }
        }
        .confirmationDialog("Delete \(restaurant.name)?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(restaurant)
                dismiss()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            CuisineIcon(cuisine: restaurant.cuisine, size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(restaurant.cuisine.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(restaurant.visitDate.formatted(date: .long, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var ratingCard: some View {
        VStack(spacing: 10) {
            StarRatingPicker(rating: $restaurant.rating, size: 34)
            Text(ratingDescription(restaurant.rating))
                .font(.headline)
                .foregroundStyle(Color.rating(restaurant.rating))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
            Text(restaurant.notes)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Map(
                initialPosition: .region(MKCoordinateRegion(center: restaurant.coordinate, latitudinalMeters: 600, longitudinalMeters: 600)),
                interactionModes: []
            ) {
                Annotation(restaurant.name, coordinate: restaurant.coordinate, anchor: .bottom) {
                    RestaurantPin(restaurant: restaurant)
                }
                .annotationTitles(.hidden)
            }
            .frame(height: 180)

            if !restaurant.address.isEmpty {
                Label(restaurant.address, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var directionsButton: some View {
        Button {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: restaurant.coordinate))
            item.name = restaurant.name
            item.openInMaps()
        } label: {
            Label("Open in Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

#Preview("Restaurant Detail") {
    let container = SampleData.makeContainer()
    let restaurant = try! container.mainContext.fetch(FetchDescriptor<Restaurant>(sortBy: [SortDescriptor(\.name)])).first!
    NavigationStack {
        RestaurantDetailView(restaurant: restaurant)
    }
    .modelContainer(container)
}
