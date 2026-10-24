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

    private(set) var board = Board()
    private(set) var moveHistory: [Move] = []

    var selectedSquare: Square?
    var legalDestinations: [Square] = []
    var pendingPromotion: Move?

    private var manualResult: GameResult?

    let mode: GameMode
    let humanColor: Piece.Color
    let botDifficulty: BotDifficulty

    init(
        mode: GameMode,
        humanColor: Piece.Color = .white,
        botDifficulty: BotDifficulty = .intermediate,
        replaying lanMoves: [String] = []
    ) {
        self.mode = mode
        self.humanColor = humanColor
        self.botDifficulty = botDifficulty

        for lan in lanMoves {
            guard applyEngineMove(lan: lan, playSound: false) else { break }
        }
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

    /// Whether the board is drawn from Black's side, i.e. the human is
    /// playing Black against the bot.
    var isBoardFlipped: Bool {
        mode == .onePlayer && humanColor == .black
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

    /// The side to move's legal moves in engine LAN form, without any
    /// promotion suffix (e.g. `"e2e4"`, or `"e7e8"` for a promotion).
    var legalEngineMoves: Set<String> {
        var moves: Set<String> = []
        for piece in board.position.pieces where piece.color == sideToMove {
            for end in board.legalMoves(forPieceAt: piece.square) {
                moves.insert(piece.square.notation + end.notation)
            }
        }
        return moves
    }

    func piece(at square: Square) -> Piece? {
        board.position.piece(at: square)
    }

    // MARK: Moves

    /// Handles a tap on `square`: selects a piece, moves a selected
    /// piece to a legal destination, or clears the selection.
    func select(_ square: Square) {
        guard !isGameOver, pendingPromotion == nil, isHumanTurn else { return }

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

    /// Starts dragging the piece on `square`: selects it (without the
    /// tap-again-to-deselect toggle) so its legal destinations show.
    /// Returns `false` if there's no piece here that can move.
    @discardableResult
    func pickUp(_ square: Square) -> Bool {
        guard !isGameOver, pendingPromotion == nil, isHumanTurn,
              let piece = board.position.piece(at: square), piece.color == sideToMove else { return false }

        selectedSquare = square
        legalDestinations = board.legalMoves(forPieceAt: square)
        return true
    }

    /// Finishes a drag that started on `start`. Moves the piece if it was
    /// dropped on a legal destination; otherwise it snaps back and stays
    /// selected so the move can still be finished with a tap.
    func drop(from start: Square, on end: Square?) {
        guard selectedSquare == start, let end, end != start, legalDestinations.contains(end) else { return }
        makeMove(from: start, to: end)
    }

    /// Attempts to move the piece at `start` to `end`. If this triggers
    /// a pawn promotion, ``pendingPromotion`` is set so the UI can
    /// prompt for a piece and later call ``completePromotion(to:)``.
    @discardableResult
    func makeMove(from start: Square, to end: Square) -> Bool {
        guard let move = board.move(pieceAt: start, to: end) else { return false }

        selectedSquare = nil
        legalDestinations = []

        if case let .promotion(pendingMove) = board.state {
            pendingPromotion = pendingMove
        } else {
            record(move)
        }

        return true
    }

    /// Completes a pending promotion with the chosen piece kind.
    func completePromotion(to kind: Piece.Kind) {
        guard let move = pendingPromotion else { return }
        let completed = board.completePromotion(of: move, to: kind)
        record(completed)
        pendingPromotion = nil
    }

    /// Applies a move chosen by the bot, given in engine LAN form
    /// (e.g. `"e2e4"`, or `"e7e8q"` for a promotion). Also used to
    /// silently replay a saved game's moves.
    @discardableResult
    func applyEngineMove(lan: String, playSound: Bool = true) -> Bool {
        guard let parsed = EngineLANParser.parse(move: lan, for: sideToMove, in: board.position) else {
            return false
        }
        // ChessKit moves a piece of either colour, so a stray engine move
        // for the other side would let it move twice in a row (and even
        // capture the king, leaving a game that can never end).
        guard parsed.piece.color == sideToMove,
              let move = board.move(pieceAt: parsed.start, to: parsed.end) else { return false }

        selectedSquare = nil
        legalDestinations = []

        if case let .promotion(pendingMove) = board.state {
            let kind = parsed.promotedPiece?.kind ?? .queen
            let completed = board.completePromotion(of: pendingMove, to: kind)
            record(completed, playSound: playSound)
        } else {
            record(move, playSound: playSound)
        }

        return true
    }

    /// Adds a finished move to the history and plays its sound.
    private func record(_ move: Move, playSound: Bool = true) {
        moveHistory.append(move)
        if playSound {
            SoundPlayer.shared.play(for: move)
        }
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
