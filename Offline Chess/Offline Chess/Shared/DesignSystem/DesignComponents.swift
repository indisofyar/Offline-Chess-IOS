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

struct PieceGlyphView: View {
    let piece: Piece
    var size: CGFloat = 36

    var body: some View {
        Text(pieceGlyph(for: piece))
            .font(.system(size: size))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .foregroundStyle(piece.color == .white ? .white : .black)
            .shadow(color: .black.opacity(piece.color == .white ? 0.35 : 0), radius: 0.5, y: 0.5)
            .accessibilityLabel("\(piece.color == .white ? "White" : "Black") \(String(describing: piece.kind))")
    }
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
/// (play vs bot, pass & play, analyze last game).
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

// MARK: - Skin Swatch

struct SkinSwatchView: View {
    let skin: BoardSkin
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            miniBoard
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isSelected ? Color.chessAccent : .clear, lineWidth: 3)
                }

            Text(skin.displayName)
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
