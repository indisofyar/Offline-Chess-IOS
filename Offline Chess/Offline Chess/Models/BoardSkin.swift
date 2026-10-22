//
//  BoardSkin.swift
//  Offline Chess
//

import SwiftUI

/// A board skin: how the board and pieces are drawn. Each skin comes in
/// one or more colours, each of which is a ``BoardSkin``.
enum BoardSkinFamily: String, CaseIterable, Identifiable {
    case classic
    case pixel
    case clubDeco

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: "Classic"
        case .pixel: "Pixel"
        case .clubDeco: "Club Deco"
        }
    }

    /// The colours this skin comes in; the first is its default.
    var colors: [BoardSkin] {
        BoardSkin.allCases.filter { $0.family == self }
    }
}

/// A selectable board skin colour, applied consistently across
/// ``BoardView`` wherever a board is rendered.
enum BoardSkin: String, CaseIterable, Identifiable, Codable {
    case classicGreen
    case walnut
    case ocean
    case midnight
    case coral
    case pixel
    case pixelRetro
    case clubDeco
    case clubDecoGilded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classicGreen: "Classic Green"
        case .walnut: "Walnut"
        case .ocean: "Ocean"
        case .midnight: "Midnight"
        case .coral: "Coral"
        case .pixel: "Pixel"
        case .pixelRetro: "Pixel Retro"
        case .clubDeco: "Club Deco"
        case .clubDecoGilded: "Club Deco Gilded"
        }
    }

    /// The skin this colour belongs to.
    var family: BoardSkinFamily {
        switch self {
        case .classicGreen, .walnut, .ocean, .midnight, .coral: .classic
        case .pixel, .pixelRetro: .pixel
        case .clubDeco, .clubDecoGilded: .clubDeco
        }
    }

    /// Name of this colour within its skin.
    var colorName: String {
        switch self {
        case .classicGreen: "Green"
        case .walnut: "Walnut"
        case .ocean: "Ocean"
        case .midnight: "Midnight"
        case .coral: "Coral"
        case .pixel, .clubDeco: "Default"
        case .pixelRetro: "Retro"
        case .clubDecoGilded: "Gilded"
        }
    }

    var lightSquare: Color {
        switch self {
        case .classicGreen: Color(red: 0.93, green: 0.93, blue: 0.82)
        case .walnut: Color(red: 0.93, green: 0.84, blue: 0.71)
        case .ocean: Color(red: 0.86, green: 0.93, blue: 0.95)
        case .midnight: Color(red: 0.70, green: 0.72, blue: 0.78)
        case .coral: Color(red: 0.98, green: 0.92, blue: 0.86)
        case .pixel: Color.white
        case .pixelRetro: Color(red: 224 / 255, green: 240 / 255, blue: 200 / 255)
        case .clubDeco, .clubDecoGilded: Color(hex: 0xE8D3A9)
        }
    }

    var darkSquare: Color {
        switch self {
        case .classicGreen: Color(red: 0.46, green: 0.59, blue: 0.34)
        case .walnut: Color(red: 0.60, green: 0.40, blue: 0.24)
        case .ocean: Color(red: 0.25, green: 0.51, blue: 0.62)
        case .midnight: Color(red: 0.24, green: 0.27, blue: 0.36)
        case .coral: Color(red: 0.82, green: 0.45, blue: 0.40)
        case .pixel: Color(red: 0.145, green: 0.145, blue: 0.145)
        case .pixelRetro: Color(red: 30 / 255, green: 50 / 255, blue: 32 / 255)
        case .clubDeco, .clubDecoGilded: Color(hex: 0x9A6A3E)
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
        case .pixel, .pixelRetro: Color.yellow.opacity(0.55)
        case .clubDeco, .clubDecoGilded: Color(hex: 0xC9A45C).opacity(0.55)
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
        // Gold, not gray: markers often sit on the grayscale sprites
        // that overhang the square from the rank in front.
        case .pixel, .pixelRetro: Color(red: 0.95, green: 0.75, blue: 0.2).opacity(0.9)
        case .clubDeco, .clubDecoGilded: Color.black.opacity(0.25)
        }
    }

    /// Asset catalog namespace of the image piece set this skin draws
    /// (e.g. `satin/wK`), or `nil` to draw Unicode glyphs.
    var pieceSet: String? {
        switch self {
        case .clubDeco: "satin"
        case .clubDecoGilded: "gilded"
        default: nil
        }
    }

    /// Wooden frame drawn around the board, if the skin has one.
    var frame: BoardFrame? {
        switch self {
        case .clubDeco, .clubDecoGilded:
            BoardFrame(color: Color(hex: 0x4A2F1B), width: 9, rule: Color(hex: 0xC9A45C))
        default: nil
        }
    }

    /// Whether this skin draws the board and pieces from the pixel-art
    /// sprite pack (see ``PixelBoardView``) rather than flat colors and
    /// Unicode glyphs.
    var usesPixelArt: Bool {
        family == .pixel
    }

    /// Asset name of the board sprite for pixel-art skins.
    var pixelBoardImage: String {
        switch self {
        case .pixelRetro: "PixelBoardRetro"
        default: "PixelBoard"
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

    /// Fill for a last-move square of the given color. Club Deco swaps the
    /// square to an opaque brass tone; other skins tint it.
    func lastMoveHighlight(onLightSquare isLight: Bool) -> Color {
        switch self {
        case .clubDeco, .clubDecoGilded: Color(hex: isLight ? 0xE3C277 : 0xB98B3F)
        default: lastMoveHighlight
        }
    }
}

/// A board frame: a wooden border with a thin rule just outside it and
/// another just inside it.
struct BoardFrame {
    let color: Color
    let width: CGFloat
    let rule: Color
    var outerRuleWidth: CGFloat = 1.5
    var innerRuleWidth: CGFloat = 1

    /// Total distance from the outer edge to the playing grid.
    var inset: CGFloat { outerRuleWidth + width }
}
