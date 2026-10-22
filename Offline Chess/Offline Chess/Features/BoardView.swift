//
//  BoardView.swift
//  Offline Chess
//

import SwiftUI
import ChessKit

/// Renders an 8x8 chess board using the selected ``BoardSkin``, with a
/// tap-to-select-then-tap-to-move interaction.
struct BoardView: View {
    let game: ChessGame
    let skin: BoardSkin

    var body: some View {
        if skin.usesPixelArt {
            PixelBoardView(game: game)
        } else {
            flatBoard
        }
    }

    private var flatBoard: some View {
        GeometryReader { proxy in
            let boardSize = min(proxy.size.width, proxy.size.height)
            let cell = boardSize / 8

            VStack(spacing: 0) {
                ForEach((1...8).reversed(), id: \.self) { rankValue in
                    HStack(spacing: 0) {
                        ForEach(Square.File.allCases, id: \.self) { file in
                            squareView(square: Square(file, Square.Rank(rankValue)), size: cell)
                        }
                    }
                }
            }
            .frame(width: boardSize, height: boardSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.black.opacity(0.15), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func squareView(square: Square, size: CGFloat) -> some View {
        let piece = game.piece(at: square)
        let isLegalDestination = game.legalDestinations.contains(square)

        ZStack {
            (square.color == .light ? skin.lightSquare : skin.darkSquare)

            if game.isLastMoveSquare(square) {
                skin.lastMoveHighlight
            }

            if game.selectedSquare == square {
                skin.selectionHighlight
            }

            if game.isCheckedKingSquare(square) {
                skin.checkHighlight
            }

            if let piece {
                PieceGlyphView(piece: piece, size: size * 0.74)
            }

            if isLegalDestination {
                if piece == nil {
                    Circle()
                        .fill(skin.legalMoveMarker)
                        .frame(width: size * 0.32, height: size * 0.32)
                } else {
                    Circle()
                        .strokeBorder(skin.legalMoveMarker, lineWidth: 3)
                        .frame(width: size * 0.86, height: size * 0.86)
                }
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            game.select(square)
        }
        .accessibilityLabel(squareAccessibilityLabel(square: square, piece: piece))
    }
}

extension ChessGame {
    func isLastMoveSquare(_ square: Square) -> Bool {
        guard let lastMove = moveHistory.last else { return false }
        return lastMove.start == square || lastMove.end == square
    }

    func isCheckedKingSquare(_ square: Square) -> Bool {
        guard isInCheck, let piece = self.piece(at: square) else { return false }
        return piece.kind == .king && piece.color == sideToMove
    }
}

func squareAccessibilityLabel(square: Square, piece: Piece?) -> String {
    if let piece {
        return "\(square.notation), \(piece.color == .white ? "white" : "black") \(String(describing: piece.kind).lowercased())"
    }
    return square.notation
}

#Preview("Board - Opening") {
    let game = ChessGame(mode: .twoPlayer)
    return BoardView(game: game, skin: .classicGreen)
        .padding()
}

#Preview("Board - Mid Game") {
    let game = ChessGame(mode: .twoPlayer)
    game.makeMove(from: .e2, to: .e4)
    game.makeMove(from: .e7, to: .e5)
    game.makeMove(from: .g1, to: .f3)
    game.makeMove(from: .b8, to: .c6)
    game.select(.f3)
    return BoardView(game: game, skin: .walnut)
        .padding()
}

#Preview("Board - Midnight Skin") {
    let game = ChessGame(mode: .twoPlayer)
    game.makeMove(from: .d2, to: .d4)
    return BoardView(game: game, skin: .midnight)
        .padding()
}

#Preview("Board - Pixel Skin") {
    let game = ChessGame(mode: .twoPlayer)
    game.makeMove(from: .e2, to: .e4)
    game.makeMove(from: .e7, to: .e5)
    game.select(.g1)
    return BoardView(game: game, skin: .pixel)
        .padding()
}

#Preview("Board - Pixel Mid Game") {
    let game = ChessGame(mode: .twoPlayer)
    game.makeMove(from: .e2, to: .e4)
    game.makeMove(from: .e7, to: .e5)
    game.makeMove(from: .g1, to: .f3)
    game.makeMove(from: .b8, to: .c6)
    game.select(.f3)
    return BoardView(game: game, skin: .pixel)
        .padding()
}
