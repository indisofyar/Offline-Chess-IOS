//
//  StarRating.swift
//  Restaurant Tracker
//

import SwiftUI

// MARK: - Star Rating (display only)

struct StarRatingView: View {
    let rating: Int
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: size * 0.15) {
            ForEach(1...5, id: \.self) { value in
                Image(systemName: value <= rating ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(value <= rating ? Color.starYellow : Color.secondary.opacity(0.35))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating) out of 5 stars")
    }
}

// MARK: - Star Rating Picker (interactive)

struct StarRatingPicker: View {
    @Binding var rating: Int
    var size: CGFloat = 32

    var body: some View {
        HStack(spacing: size * 0.25) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        rating = value
                    }
                } label: {
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .font(.system(size: size, weight: .semibold))
                        .foregroundStyle(value <= rating ? Color.starYellow : Color.secondary.opacity(0.35))
                        .scaleEffect(value == rating ? 1.15 : 1)
                }
                .buttonStyle(.borderless)
            }
        }
        .sensoryFeedback(.selection, trigger: rating)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(rating) out of 5 stars")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: rating = Restaurant.clamp(rating + 1)
            case .decrement: rating = Restaurant.clamp(rating - 1)
            @unknown default: break
            }
        }
    }
}

// MARK: - Rating Label

/// Short text description of a star rating, e.g. "Excellent".
func ratingDescription(_ rating: Int) -> String {
    switch rating {
    case ...1: return "Poor"
    case 2: return "Fair"
    case 3: return "Good"
    case 4: return "Great"
    default: return "Excellent"
    }
}

#Preview("Star Ratings") {
    @Previewable @State var rating = 4
    VStack(spacing: 24) {
        StarRatingPicker(rating: $rating)
        Text(ratingDescription(rating))
            .font(.headline)
        ForEach((1...5).reversed(), id: \.self) { value in
            StarRatingView(rating: value, size: 18)
        }
    }
    .padding()
}
