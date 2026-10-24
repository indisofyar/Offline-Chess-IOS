//
//  DesignComponents.swift
//  Offline Chess
//

import SwiftUI
import ChessKit

// MARK: - Piece Glyph

/// Maps a ``Piece`` to its Unicode chess glyph, rendered as text so no
/// external image assets are required.
func pieceGlyph(for piece: Piece) -> String {
    switch (piece.color, piece.kind) {
    case (.white, .king): "♔"
    case (.white, .queen): "♕"
    case (.white, .rook): "♖"
    case (.white, .bishop): "♗"
    case (.white, .knight): "♘"
    case (.white, .pawn): "♙"
    case (.black, .king): "♚"
    case (.black, .queen): "♛"
    case (.black, .rook): "♜"
    case (.black, .bishop): "♝"
    case (.black, .knight): "♞"
    case (.black, .pawn): "♟︎"
    }
}

/// Draws a single piece: the skin's sprite for pixel-art skins, its
/// piece image for skins with an image piece set, otherwise its Unicode
/// glyph.
struct PieceGlyphView: View {
    let piece: Piece
    var size: CGFloat = 36
    var skin: BoardSkin?

    var body: some View {
        Group {
            if skin?.usesPixelArt == true {
                Image(PixelBoardView.spriteName(for: piece))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else if let pieceSet = skin?.pieceSet {
                Image("\(pieceSet)/\(pieceAssetCode(for: piece))")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Text(pieceGlyph(for: piece))
                    .font(.system(size: size))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(piece.color == .white ? .white : .black)
                    .shadow(color: .black.opacity(piece.color == .white ? 0.35 : 0), radius: 0.5, y: 0.5)
            }
        }
        .accessibilityLabel("\(piece.color == .white ? "White" : "Black") \(String(describing: piece.kind))")
    }
}

/// FEN-style asset code for a piece image: `w`/`b` then the uppercase
/// piece letter, e.g. `wK`, `bN`.
func pieceAssetCode(for piece: Piece) -> String {
    let side = piece.color == .white ? "w" : "b"
    let letter = switch piece.kind {
    case .king: "K"
    case .queen: "Q"
    case .rook: "R"
    case .bishop: "B"
    case .knight: "N"
    case .pawn: "P"
    }
    return side + letter
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Menu Card Button

/// A big tappable card used on the home screen for the primary actions
/// (play vs bot, pass & play, analyse last game).
struct MenuCardButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.gradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Difficulty Row

struct DifficultyRow: View {
    let difficulty: BotDifficulty
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.chessAccent.opacity(isSelected ? 1 : 0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: difficulty.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color.chessAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(difficulty.displayName)
                    .font(.headline)
                Text(difficulty.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.chessAccent)
            }
        }
        .padding(12)
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? Color.chessAccent : .clear, lineWidth: 2)
        }
    }
}

// MARK: - Difficulty Tile

/// Compact, vertically stacked version of ``DifficultyRow`` for grid
/// layouts.
struct DifficultyTile: View {
    let difficulty: BotDifficulty
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.chessAccent.opacity(isSelected ? 1 : 0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: difficulty.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color.chessAccent)
            }

            VStack(spacing: 2) {
                Text(difficulty.displayName)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(difficulty.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? Color.chessAccent : .clear, lineWidth: 2)
        }
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.chessAccent)
                    .padding(8)
            }
        }
    }
}

// MARK: - Skin Swatch

struct SkinSwatchView: View {
    let skin: BoardSkin
    let isSelected: Bool
    var title: String?

    var body: some View {
        VStack(spacing: 8) {
            miniBoard
                .frame(width: 72, height: 72)
                .overlay {
                    if skin.usesPixelArt {
                        Image("PixelWhiteKnight")
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 56)
                    } else if let pieceSet = skin.pieceSet {
                        Image("\(pieceSet)/wN")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(height: 56)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? Color.chessAccent : .clear, lineWidth: 3)
                }

            Text(title ?? skin.displayName)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? Color.chessAccent : .secondary)
        }
    }

    private var miniBoard: some View {
        GeometryReader { proxy in
            let cell = proxy.size.width / 4
            VStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { column in
                            ((row + column).isMultiple(of: 2) ? skin.lightSquare : skin.darkSquare)
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Move Judgment Badge

struct JudgmentBadge: View {
    let judgment: MoveJudgment

    var body: some View {
        Text(judgment.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(Color.judgmentColor(judgment).gradient, in: Capsule())
    }
}

#Preview("Design Components") {
    ScrollView {
        VStack(spacing: 20) {
            MenuCardButton(icon: "cpu", title: "Play vs Bot", subtitle: "Pick a difficulty", tint: .chessAccent) {}
            DifficultyRow(difficulty: .intermediate, isSelected: true)
            HStack {
                SkinSwatchView(skin: .classicGreen, isSelected: true)
                SkinSwatchView(skin: .walnut, isSelected: false)
                SkinSwatchView(skin: .midnight, isSelected: false)
                SkinSwatchView(skin: .pixel, isSelected: false)
                SkinSwatchView(skin: .clubDecoGilded, isSelected: false)
            }
            HStack {
                ForEach([Piece.Kind.queen, .rook, .bishop, .knight], id: \.self) { kind in
                    PieceGlyphView(piece: Piece(kind, color: .white, square: .e8), size: 40, skin: .pixel)
                }
            }
            HStack {
                JudgmentBadge(judgment: .brilliant)
                JudgmentBadge(judgment: .best)
                JudgmentBadge(judgment: .blunder)
            }
            HStack {
                StatTile(icon: "target", title: "Accuracy", value: "94%", color: .chessAccent)
                StatTile(icon: "flame.fill", title: "Streak", value: "3", color: .orange)
            }
        }
        .padding()
    }
}
