//
//  ChessGame.swift
//  Offline Chess
//

import Foundation
import Observation
import ChessKit

/// A readable description of why & how a game ended.
struct GameResult: Equatable {
    enum Reason: Equatable {
        case checkmate
        case stalemate
        case draw(Board.State.DrawReason)
        case resignation
        case drawByAgreement
    }

    /// `nil` for a draw.
    let winner: Piece.Color?
    let reason: Reason

    var description: String {
        switch reason {
        case .checkmate:
            return "Checkmate — \(colorName(winner)) wins"
        case .stalemate:
            return "Draw by stalemate"
        case let .draw(drawReason):
            return "Draw by \(drawReason.readableDescription)"
        case .resignation:
            return "\(colorName(winner)) wins by resignation"
        case .drawByAgreement:
            return "Draw by agreement"
        }
    }

    private func colorName(_ color: Piece.Color?) -> String {
        switch color {
        case .white: "White"
        case .black: "Black"
        case nil: "Nobody"
        }
    }
}

extension Board.State.DrawReason {
    var readableDescription: String {
        switch self {
        case .agreement: "agreement"
        case .fiftyMoves: "the 50-move rule"
        case .insufficientMaterial: "insufficient material"
        case .repetition: "threefold repetition"
        case .stalemate: "stalemate"
        }
    }
}

/// Observable view model that wraps a ChessKit ``Board`` with
/// everything a chess UI needs: square selection, legal-move
/// highlighting, promotion prompts, move history and game-over state.
@MainActor
@Observable
final class ChessGame {

    // ChessKit's `Attacks` cache populates its lookup tables (including
    // the bishop/rook magic-bitboard tables) on the first `Board()`
    // construction. That population is lock-protected on the write
    // side, but `Board`'s attack *lookups* read the cache directly,
    // unlocked. Two `Board()`s constructed for the first time at
    // nearly the same moment on different threads (e.g. several
    // #Previews rendering concurrently, each building their own
    // `ChessGame`) can race on that first population and corrupt the
    // heap. A plain eager call at startup only changes *ordering* —
    // it doesn't stop a genuinely concurrent `Board()` elsewhere from
    // racing with it. A `static let` does: Swift guarantees its
    // initializer runs exactly once and that every other thread
    // touching it *blocks* until that run completes, so this is real
    // cross-thread synchronization, not a hopeful race-narrowing.
    private static let attacksWarmedUp: Void = { _ = Board() }()

    private(set) var board: Board
    private(set) var moveHistory: [Move] = []

    var selectedSquare: Square?
    var legalDestinations: [Square] = []
    var pendingPromotion: Move?

    private var manualResult: GameResult?

    let mode: GameMode
    let humanColor: Piece.Color
    let botDifficulty: BotDifficulty

    init(mode: GameMode, humanColor: Piece.Color = .white, botDifficulty: BotDifficulty = .intermediate) {
        _ = Self.attacksWarmedUp
        self.board = Board()
        self.mode = mode
        self.humanColor = humanColor
        self.botDifficulty = botDifficulty
    }

    // MARK: Derived state

    var sideToMove: Piece.Color {
        board.position.sideToMove
    }

    /// Whether it's currently a human's turn to move (always true in
    /// 2-player pass-and-play; only true on the human's color in a
    /// 1-player game).
    var isHumanTurn: Bool {
        mode == .twoPlayer || sideToMove == humanColor
    }

    var result: GameResult? {
        if let manualResult { return manualResult }

        switch board.state {
        case let .checkmate(color):
            return GameResult(winner: color.opposite, reason: .checkmate)
        case let .draw(reason):
            return GameResult(winner: nil, reason: reason == .stalemate ? .stalemate : .draw(reason))
        default:
            return nil
        }
    }

    var isGameOver: Bool {
        result != nil
    }

    var isInCheck: Bool {
        if case .check = board.state { return true }
        if case .checkmate = board.state { return true }
        return false
    }

    func piece(at square: Square) -> Piece? {
        board.position.piece(at: square)
    }

    // MARK: Moves

    /// Handles a tap on `square`: selects a piece, moves a selected
    /// piece to a legal destination, or clears the selection.
    func select(_ square: Square) {
        guard !isGameOver, pendingPromotion == nil else { return }

        if let selected = selectedSquare {
            if selected == square {
                selectedSquare = nil
                legalDestinations = []
                return
            }

            if legalDestinations.contains(square) {
                makeMove(from: selected, to: square)
                return
            }
        }

        if let piece = board.position.piece(at: square), piece.color == sideToMove {
            selectedSquare = square
            legalDestinations = board.legalMoves(forPieceAt: square)
        } else {
            selectedSquare = nil
            legalDestinations = []
        }
    }

    /// Attempts to move the piece at `start` to `end`. If this triggers
    /// a pawn promotion, ``pendingPromotion`` is set so the UI can
    /// prompt for a piece and later call ``completePromotion(to:)``.
    @discardableResult
    func makeMove(from start: Square, to end: Square) -> Bool {
        // Mutate a local copy and reassign the whole value, rather than
        // calling a `mutating func` directly on `board` (an @Observable-
        // tracked stored property), to avoid going through the macro's
        // in-place `_modify` accessor for a large value type.
        var updatedBoard = board
        guard let move = updatedBoard.move(pieceAt: start, to: end) else { return false }

        selectedSquare = nil
        legalDestinations = []

        if case let .promotion(pendingMove) = updatedBoard.state {
            pendingPromotion = pendingMove
        } else {
            moveHistory.append(move)
        }

        board = updatedBoard
        return true
    }

    /// Completes a pending promotion with the chosen piece kind.
    func completePromotion(to kind: Piece.Kind) {
        guard let move = pendingPromotion else { return }
        var updatedBoard = board
        let completed = updatedBoard.completePromotion(of: move, to: kind)
        moveHistory.append(completed)
        pendingPromotion = nil
        board = updatedBoard
    }

    /// Applies a move chosen by the bot, given in engine LAN form
    /// (e.g. `"e2e4"`, or `"e7e8q"` for a promotion).
    @discardableResult
    func applyEngineMove(lan: String) -> Bool {
        guard let parsed = EngineLANParser.parse(move: lan, for: sideToMove, in: board.position) else {
            return false
        }

        var updatedBoard = board
        guard let move = updatedBoard.move(pieceAt: parsed.start, to: parsed.end) else { return false }

        selectedSquare = nil
        legalDestinations = []

        if case let .promotion(pendingMove) = updatedBoard.state {
            let kind = parsed.promotedPiece?.kind ?? .queen
            let completed = updatedBoard.completePromotion(of: pendingMove, to: kind)
            moveHistory.append(completed)
        } else {
            moveHistory.append(move)
        }

        board = updatedBoard
        return true
    }

    func resign(as color: Piece.Color) {
        guard !isGameOver else { return }
        manualResult = GameResult(winner: color.opposite, reason: .resignation)
    }

    func agreeToDraw() {
        guard !isGameOver else { return }
        manualResult = GameResult(winner: nil, reason: .drawByAgreement)
    }

    // MARK: Export

    var lanMoves: [String] { moveHistory.map(\.lan) }
    var sanMoves: [String] { moveHistory.map(\.san) }

    /// A simple numbered move-text PGN body (no tag pairs), suitable
    /// for display or export.
    var pgn: String {
        var parts: [String] = []

        for (index, san) in sanMoves.enumerated() {
            if index % 2 == 0 {
                parts.append("\(index / 2 + 1).")
            }
            parts.append(san)
        }

        return parts.joined(separator: " ")
    }
}
