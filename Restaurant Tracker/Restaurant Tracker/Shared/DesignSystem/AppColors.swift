//
//  AppColors.swift
//  Restaurant Tracker
//

import SwiftUI

extension Color {
    static var appControlBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    static var appWindowBackground: Color {
        Color(uiColor: .systemBackground)
    }

    static let starYellow = Color(red: 1.0, green: 0.78, blue: 0.0)

    /// Pin / badge colour for a 1–5 star rating.
    static func rating(_ rating: Int) -> Color {
        switch rating {
        case ...1: return .red
        case 2: return .orange
        case 3: return Color(red: 0.95, green: 0.7, blue: 0.0)
        case 4: return .mint
        default: return .green
        }
    }
}
