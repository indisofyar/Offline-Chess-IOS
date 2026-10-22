//
//  AppColors.swift
//  Offline Chess
//

import SwiftUI

extension Color {
    /// A color from a 24-bit `0xRRGGBB` sRGB value.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static var appControlBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    static var appWindowBackground: Color {
        Color(uiColor: .systemBackground)
    }

    /// The app's primary accent, a deep chess-board green.
    static let chessAccent = Color(red: 0.24, green: 0.48, blue: 0.33)

    /// A warm gold used for premium/crown accents.
    static let chessGold = Color(red: 0.80, green: 0.64, blue: 0.20)

    static func judgmentColor(_ judgment: MoveJudgment) -> Color {
        switch judgment {
        case .brilliant: Color(red: 0.11, green: 0.66, blue: 0.62)
        case .best: Color(red: 0.24, green: 0.56, blue: 0.32)
        case .excellent: Color(red: 0.36, green: 0.62, blue: 0.33)
        case .good: Color(red: 0.55, green: 0.55, blue: 0.55)
        case .inaccuracy: Color(red: 0.85, green: 0.64, blue: 0.13)
        case .mistake: Color(red: 0.88, green: 0.45, blue: 0.13)
        case .blunder: Color(red: 0.80, green: 0.20, blue: 0.20)
        }
    }
}
