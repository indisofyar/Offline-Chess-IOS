//
//  BoardView.swift
//  Offline Chess
//

import SwiftUI
import ChessKit

/// Renders an 8x8 chess board using the selected ``BoardSkin``. Pieces
/// move either by tapping the piece then its destination, or by
/// dragging the piece onto its destination.
struct BoardView: View {
    let game: ChessGame
    let skin: BoardSkin

    @State private var drag: PieceDrag?

    var body: some View {
        if skin.usesPixelArt {
            PixelBoardView(game: game, skin: skin)
        } else {
            flatBoard
        }
    }

    private var flatBoard: some View {
        GeometryReader { proxy in
            let boardSize = min(proxy.size.width, proxy.size.height)
            let inset = skin.frame?.inset ?? 0
            let cell = (boardSize - inset * 2) / 8
            let cornerRadius: CGFloat = skin.frame == nil ? 10 : 0

            VStack(spacing: 0) {
                ForEach((1...8).reversed(), id: \.self) { rankValue in
                    HStack(spacing: 0) {
                        ForEach(Square.File.allCases, id: \.self) { file in
                            squareView(square: Square(file, Square.Rank(rankValue)), size: cell)
                        }
                    }
                }
            }
            .frame(width: cell * 8, height: cell * 8)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                if skin.frame == nil {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                }
            }
            .padding(inset)
            .background {
                if let frame = skin.frame {
                    frameView(frame)
                }
            }
            // Outside the clip so a dragged piece can leave the board's edge.
            .overlay(alignment: .topLeading) {
                if let drag, drag.isDragging, let piece = game.piece(at: drag.start) {
                    PieceGlyphView(piece: piece, size: cell * pieceScale * 1.3, skin: skin)
                        .position(drag.location)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .gesture(pieceDragGesture(game: game, drag: $drag) {
                square(at: CGPoint(x: $0.x - inset, y: $0.y - inset), cell: cell)
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Piece size as a fraction of the square. Image piece sets include
    /// their own padding, so they're drawn larger than glyphs.
    private var pieceScale: CGFloat {
        skin.pieceSet == nil ? 0.74 : 0.94
    }

    /// The wooden border, with a rule outside it and another just inside
    /// it, against the grid.
    private func frameView(_ frame: BoardFrame) -> some View {
        Rectangle()
            .fill(frame.color)
            .overlay {
                Rectangle()
                    .strokeBorder(frame.rule, lineWidth: frame.outerRuleWidth)
            }
            .overlay {
                Rectangle()
                    .strokeBorder(frame.rule, lineWidth: frame.innerRuleWidth)
                    .padding(frame.inset - frame.innerRuleWidth)
            }
    }

    private func square(at location: CGPoint, cell: CGFloat) -> Square? {
        let column = Int((location.x / cell).rounded(.down))
        let row = Int((location.y / cell).rounded(.down))
        guard (0..<8).contains(column), (0..<8).contains(row) else { return nil }
        return Square(Square.File.allCases[column], Square.Rank(8 - row))
    }

    @ViewBuilder
    private func squareView(square: Square, size: CGFloat) -> some View {
        let piece = game.piece(at: square)
        let isLegalDestination = game.legalDestinations.contains(square)

        ZStack {
            (square.color == .light ? skin.lightSquare : skin.darkSquare)

            if game.isLastMoveSquare(square) {
                skin.lastMoveHighlight(onLightSquare: square.color == .light)
            }

            if game.selectedSquare == square {
                skin.selectionHighlight
            }

            if game.isCheckedKingSquare(square) {
                skin.checkHighlight
            }

            if let piece, !(drag?.isDragging == true && drag?.start == square) {
                PieceGlyphView(piece: piece, size: size * pieceScale, skin: skin)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(squareAccessibilityLabel(square: square, piece: piece))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { game.select(square) }
    }
}

/// An in-progress touch on the board that may become a piece drag.
struct PieceDrag {
    /// The square the touch started on.
    let start: Square
    /// Current touch location, in the board's coordinate space.
    var location: CGPoint
    /// Whether the touch has moved far enough to stop counting as a tap.
    var hasMoved = false
    /// Whether the piece on ``start`` was picked up and follows the touch.
    var isDragging = false
}

/// Handles both taps and drags on a board. A touch that barely moves is
/// a tap (``ChessGame/select(_:)``); one that moves picks up the piece
/// it started on and drops it wherever the touch ends.
///
/// One board-wide gesture rather than per-square tap gestures, so taps
/// and drags can't both fire for the same touch.
func pieceDragGesture(
    game: ChessGame,
    drag: Binding<PieceDrag?>,
    square: @escaping (CGPoint) -> Square?
) -> some Gesture {
    DragGesture(minimumDistance: 0)
        .onChanged { value in
            if drag.wrappedValue == nil {
                guard let start = square(value.startLocation) else { return }
                drag.wrappedValue = PieceDrag(start: start, location: value.startLocation)
            }
            guard var current = drag.wrappedValue else { return }

            current.location = value.location
            if !current.hasMoved, hypot(value.translation.width, value.translation.height) > 8 {
                current.hasMoved = true
                current.isDragging = game.pickUp(current.start)
            }
            drag.wrappedValue = current
        }
        .onEnded { value in
            defer { drag.wrappedValue = nil }
            guard let current = drag.wrappedValue else { return }

            if !current.hasMoved {
                game.select(current.start)
            } else if current.isDragging {
                game.drop(from: current.start, on: square(value.location))
            }
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

#Preview("Board - Club Deco") {
    let game = ChessGame(mode: .twoPlayer)
    game.makeMove(from: .e2, to: .e4)
    game.makeMove(from: .e7, to: .e5)
    game.makeMove(from: .g1, to: .f3)
    game.makeMove(from: .b8, to: .c6)
    game.select(.f3)
    return BoardView(game: game, skin: .clubDeco)
        .padding()
}

#Preview("Board - Club Deco Gilded") {
    let game = ChessGame(mode: .twoPlayer)
    game.makeMove(from: .d2, to: .d4)
    game.makeMove(from: .g8, to: .f6)
    return BoardView(game: game, skin: .clubDecoGilded)
        .padding()
}

#Preview("Board - Cartoon") {
    let game = ChessGame(mode: .twoPlayer)
    game.makeMove(from: .e2, to: .e4)
    game.makeMove(from: .e7, to: .e5)
    game.makeMove(from: .g1, to: .f3)
    game.makeMove(from: .b8, to: .c6)
    game.select(.f3)
    return BoardView(game: game, skin: .cartoon)
        .padding()
}

#Preview("Board - Geometric") {
    let game = ChessGame(mode: .twoPlayer)
    game.makeMove(from: .e2, to: .e4)
    game.makeMove(from: .e7, to: .e5)
    game.makeMove(from: .g1, to: .f3)
    game.makeMove(from: .b8, to: .c6)
    game.select(.f3)
    return BoardView(game: game, skin: .geometric)
        .padding()
}
