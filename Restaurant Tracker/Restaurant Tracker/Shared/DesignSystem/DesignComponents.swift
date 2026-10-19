//
//  DesignComponents.swift
//  Restaurant Tracker
//

import SwiftUI

// MARK: - Restaurant Pin

struct RestaurantPin: View {
    let name: String
    let cuisine: Cuisine
    let rating: Int
    var isSelected = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.rating(rating).gradient)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(.white, lineWidth: 2.5))
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                Text(cuisine.emoji)
                    .font(.system(size: 20))
            }
            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(180))
                .offset(y: -3)
        }
        .scaleEffect(isSelected ? 1.25 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .accessibilityLabel("\(name), \(rating) stars")
    }
}

// MARK: - Rating Badge

struct RatingBadge: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 11, weight: .bold))
            Text("\(rating)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.rating(rating).gradient, in: Capsule())
    }
}

// MARK: - Cuisine Icon

struct CuisineIcon: View {
    let cuisine: Cuisine
    var size: CGFloat = 44

    var body: some View {
        Text(cuisine.emoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(color)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background {
                    if isSelected {
                        Capsule().fill(Color.accentColor)
                    } else {
                        Capsule().fill(.regularMaterial)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Design Components") {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            RestaurantPin(name: "Dishoom", cuisine: .indian, rating: 5)
            RestaurantPin(name: "Kanada-Ya", cuisine: .japanese, rating: 4)
            RestaurantPin(name: "The Patty Shack", cuisine: .american, rating: 3)
            RestaurantPin(name: "Corner Noodle Bar", cuisine: .thai, rating: 2, isSelected: true)
        }
        HStack {
            ForEach(1...5, id: \.self) { RatingBadge(rating: $0) }
        }
        HStack {
            StatTile(icon: "fork.knife", title: "Visited", value: "12", color: .orange)
            StatTile(icon: "star.fill", title: "Average", value: "4.2", color: .yellow)
        }
        HStack {
            FilterChip(title: "All", isSelected: true) {}
            FilterChip(title: "4★+", isSelected: false) {}
        }
    }
    .padding()
}
