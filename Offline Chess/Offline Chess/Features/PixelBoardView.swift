//
//  PixelBoardView.swift
//  Offline Chess
//

import SwiftUI
import ChessKit

/// Renders the ``BoardSkin/pixel`` skin from its sprite pack: a
/// slightly foreshortened board (48x40 sprite-pixel squares with a front
/// lip) and upright piece sprites that stand on their square and overlap
/// the square behind them.
///
/// All layout is done in the sprite pack's own pixel units and scaled to
/// fit, so the art stays aligned at any size.
struct PixelBoardView: View {
    let game: ChessGame

    @State private var drag: PieceDrag?

    private let skin = BoardSkin.pixel

    // Measurements of the `PixelBoard` asset, in sprite pixels.
    private static let boardWidth: CGFloat = 390
    private static let boardHeight: CGFloat = 346
    private static let gridOrigin = CGPoint(x: 3, y: 3)
    private static let cellWidth: CGFloat = 48
    private static let cellHeight: CGFloat = 40
    /// Gap between a sprite's bottom edge and its square's bottom edge.
    private static let pieceBaseInset: CGFloat = 2
    /// Room above the board for back-rank pieces (the king is the tallest
    /// sprite) to stand up past the board's top edge.
    private static let headroom: CGFloat = 72

    private static let totalHeight = headroom + boardHeight

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / Self.boardWidth, proxy.size.height / Self.totalHeight)

            ZStack(alignment: .topLeading) {
                Image("PixelBoard")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: Self.boardWidth * scale, height: Self.boardHeight * scale)
                    .offset(y: Self.headroom * scale)

                // Each layer gets its own container so the layers' ForEach
                // IDs (0..<64 in all three) don't collide as siblings.
                ZStack(alignment: .topLeading) {
                    ForEach(0..<64, id: \.self) { index in
                        squareView(square: square(at: index), scale: scale)
                    }
                }
                .frame(width: Self.boardWidth * scale, height: Self.totalHeight * scale, alignment: .topLeading)

                // Back ranks first so nearer pieces overlap the ones behind.
                ZStack(alignment: .topLeading) {
                    ForEach(0..<64, id: \.self) { index in
                        pieceView(square: square(at: index), scale: scale)
                    }
                }
                .frame(width: Self.boardWidth * scale, height: Self.totalHeight * scale, alignment: .topLeading)
                .allowsHitTesting(false)

                ZStack(alignment: .topLeading) {
                    ForEach(0..<64, id: \.self) { index in
                        legalMoveMarker(square: square(at: index), scale: scale)
                    }
                }
                .frame(width: Self.boardWidth * scale, height: Self.totalHeight * scale, alignment: .topLeading)
                .allowsHitTesting(false)

                draggedPiece(scale: scale)
            }
            .frame(width: Self.boardWidth * scale, height: Self.totalHeight * scale)
            .contentShape(Rectangle())
            .gesture(pieceDragGesture(game: game, drag: $drag) { square(at: $0, scale: scale) })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(Self.boardWidth / Self.totalHeight, contentMode: .fit)
    }

    /// Squares in drawing order: rank 8 (top, furthest away) to rank 1,
    /// a-file to h-file.
    private func square(at index: Int) -> Square {
        let file = Square.File.allCases[index % 8]
        return Square(file, Square.Rank(8 - index / 8))
    }

    /// The square under `location` (in view points), if any.
    private func square(at location: CGPoint, scale: CGFloat) -> Square? {
        let x = location.x / scale - Self.gridOrigin.x
        let y = location.y / scale - Self.headroom - Self.gridOrigin.y
        let column = Int((x / Self.cellWidth).rounded(.down))
        let row = Int((y / Self.cellHeight).rounded(.down))
        guard (0..<8).contains(column), (0..<8).contains(row) else { return nil }
        return Square(Square.File.allCases[column], Square.Rank(8 - row))
    }

    /// Top-left corner of a square, in sprite pixels from the view's origin.
    private func origin(of square: Square) -> CGPoint {
        let column = CGFloat(Square.File.allCases.firstIndex(of: square.file) ?? 0)
        let row = CGFloat(8 - square.rank.value)
        return CGPoint(
            x: Self.gridOrigin.x + column * Self.cellWidth,
            y: Self.headroom + Self.gridOrigin.y + row * Self.cellHeight
        )
    }

    private func squareView(square: Square, scale: CGFloat) -> some View {
        let piece = game.piece(at: square)
        let topLeft = origin(of: square)

        return ZStack {
            Color.clear

            if game.isLastMoveSquare(square) {
                skin.lastMoveHighlight
            }

            if game.selectedSquare == square {
                skin.selectionHighlight
            }

            if game.isCheckedKingSquare(square) {
                skin.checkHighlight
            }
        }
        .frame(width: Self.cellWidth * scale, height: Self.cellHeight * scale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(squareAccessibilityLabel(square: square, piece: piece))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { game.select(square) }
        .offset(x: topLeft.x * scale, y: topLeft.y * scale)
    }

    @ViewBuilder
    private func pieceView(square: Square, scale: CGFloat) -> some View {
        if let piece = game.piece(at: square), !(drag?.isDragging == true && drag?.start == square) {
            let topLeft = origin(of: square)
            let height = Self.spriteHeight(for: piece.kind)
            let squareBottom = topLeft.y + Self.cellHeight

            Image(Self.spriteName(for: piece))
                .interpolation(.none)
                .resizable()
                .frame(width: Self.cellWidth * scale, height: height * scale)
                .offset(x: topLeft.x * scale, y: (squareBottom - Self.pieceBaseInset - height) * scale)
        }
    }

    /// The piece being dragged, standing with its base just below the
    /// touch so the finger doesn't cover it.
    @ViewBuilder
    private func draggedPiece(scale: CGFloat) -> some View {
        if let drag, drag.isDragging, let piece = game.piece(at: drag.start) {
            let height = Self.spriteHeight(for: piece.kind)

            Image(Self.spriteName(for: piece))
                .interpolation(.none)
                .resizable()
                .frame(width: Self.cellWidth * scale, height: height * scale)
                .position(x: drag.location.x, y: drag.location.y + (Self.cellHeight / 2 - height / 2) * scale)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func legalMoveMarker(square: Square, scale: CGFloat) -> some View {
        if game.legalDestinations.contains(square) {
            let topLeft = origin(of: square)
            let isCapture = game.piece(at: square) != nil

            // Ellipses rather than circles to match the board's perspective.
            Group {
                if isCapture {
                    Ellipse()
                        .strokeBorder(skin.legalMoveMarker, lineWidth: 3 * scale)
                        .frame(width: Self.cellWidth * 0.86 * scale, height: Self.cellHeight * 0.86 * scale)
                } else {
                    Ellipse()
                        .fill(skin.legalMoveMarker)
                        .frame(width: Self.cellWidth * 0.32 * scale, height: Self.cellHeight * 0.32 * scale)
                }
            }
            .frame(width: Self.cellWidth * scale, height: Self.cellHeight * scale)
            .offset(x: topLeft.x * scale, y: topLeft.y * scale)
        }
    }

    static func spriteName(for piece: Piece) -> String {
        let color = piece.color == .white ? "White" : "Black"
        let kind: String = switch piece.kind {
        case .king: "King"
        case .queen: "Queen"
        case .rook: "Rook"
        case .bishop: "Bishop"
        case .knight: "Knight"
        case .pawn: "Pawn"
        }
        return "Pixel\(color)\(kind)"
    }

    /// Height of each sprite in the pack; all are 48 pixels wide.
    private static func spriteHeight(for kind: Piece.Kind) -> CGFloat {
        switch kind {
        case .king: 112
        case .queen: 96
        default: 80
        }
    }
}

#Preview("Pixel Board - Opening") {
    PixelBoardView(game: ChessGame(mode: .twoPlayer))
        .padding()
}
