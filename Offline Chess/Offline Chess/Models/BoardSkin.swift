//
//  BoardSkin.swift
//  Offline Chess
//

import SwiftUI

/// A selectable board color palette, applied consistently across
/// ``BoardView`` wherever a board is rendered.
enum BoardSkin: String, CaseIterable, Identifiable, Codable {
    case classicGreen
    case walnut
    case ocean
    case midnight
    case coral

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classicGreen: "Classic Green"
        case .walnut: "Walnut"
        case .ocean: "Ocean"
        case .midnight: "Midnight"
        case .coral: "Coral"
        }
    }

    var lightSquare: Color {
        switch self {
        case .classicGreen: Color(red: 0.93, green: 0.93, blue: 0.82)
        case .walnut: Color(red: 0.93, green: 0.84, blue: 0.71)
        case .ocean: Color(red: 0.86, green: 0.93, blue: 0.95)
        case .midnight: Color(red: 0.70, green: 0.72, blue: 0.78)
        case .coral: Color(red: 0.98, green: 0.92, blue: 0.86)
        }
    }

    var darkSquare: Color {
        switch self {
        case .classicGreen: Color(red: 0.46, green: 0.59, blue: 0.34)
        case .walnut: Color(red: 0.60, green: 0.40, blue: 0.24)
        case .ocean: Color(red: 0.25, green: 0.51, blue: 0.62)
        case .midnight: Color(red: 0.24, green: 0.27, blue: 0.36)
        case .coral: Color(red: 0.82, green: 0.45, blue: 0.40)
        }
    }

    /// Highlight for the currently selected square.
    var selectionHighlight: Color {
        switch self {
        case .classicGreen: Color.yellow.opacity(0.55)
        case .walnut: Color.yellow.opacity(0.5)
        case .ocean: Color.white.opacity(0.55)
        case .midnight: Color.cyan.opacity(0.45)
        case .coral: Color.yellow.opacity(0.55)
        }
    }

    /// Dot/ring marker for legal destination squares.
    var legalMoveMarker: Color {
        switch self {
        case .classicGreen: Color.black.opacity(0.25)
        case .walnut: Color.black.opacity(0.25)
        case .ocean: Color.black.opacity(0.22)
        case .midnight: Color.white.opacity(0.35)
        case .coral: Color.black.opacity(0.25)
        }
    }

    /// Tint for the square a check is occurring on.
    var checkHighlight: Color {
        Color.red.opacity(0.55)
    }

    /// Tint used to highlight the most recent move's start/end squares.
    var lastMoveHighlight: Color {
        switch self {
        case .midnight: Color.blue.opacity(0.35)
        default: Color.blue.opacity(0.25)
        }
    }
}
