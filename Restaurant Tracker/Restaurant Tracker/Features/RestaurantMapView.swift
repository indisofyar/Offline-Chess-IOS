//
//  RestaurantMapView.swift
//  Restaurant Tracker
//

import SwiftUI
import SwiftData
import MapKit

struct RestaurantMapView: View {
    @Query private var restaurants: [Restaurant]

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedRestaurant: Restaurant?
    @State private var minimumRating = 1
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var showingAddRestaurant = false

    private var filteredRestaurants: [Restaurant] {
        restaurants.filter { $0.rating >= minimumRating }
    }

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            ForEach(filteredRestaurants) { restaurant in
                Annotation(restaurant.name, coordinate: restaurant.coordinate, anchor: .bottom) {
                    RestaurantPin(restaurant: restaurant, isSelected: selectedRestaurant?.id == restaurant.id)
                        .onTapGesture {
                            selectedRestaurant = restaurant
                        }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleRegion = context.region
        }
        .safeAreaInset(edge: .top) {
            ratingFilter
        }
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
        .sheet(item: $selectedRestaurant) { restaurant in
            NavigationStack {
                RestaurantDetailView(restaurant: restaurant)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingAddRestaurant) {
            NavigationStack {
                RestaurantFormView(searchRegion: visibleRegion)
            }
        }
    }

    private var ratingFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All \(restaurants.count)", isSelected: minimumRating == 1) {
                    minimumRating = 1
                }
                ForEach([3, 4, 5], id: \.self) { stars in
                    FilterChip(title: stars == 5 ? "5★" : "\(stars)★+", isSelected: minimumRating == stars) {
                        minimumRating = stars
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var addButton: some View {
        Button {
            showingAddRestaurant = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor.gradient, in: Circle())
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .padding(20)
        .accessibilityLabel("Add restaurant")
    }
}

#Preview("Map") {
    RestaurantMapView()
        .modelContainer(SampleData.makeContainer())
}

#Preview("Map Empty") {
    RestaurantMapView()
        .modelContainer(SampleData.makeContainer(empty: true))
}
