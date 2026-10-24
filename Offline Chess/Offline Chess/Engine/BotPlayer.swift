//
//  BotPlayer.swift
//  Offline Chess
//

import Foundation
import Observation

/// Picks moves on behalf of the bot side of a 1-player game, using
/// ``EngineManager`` configured to the selected ``BotDifficulty``.
@MainActor
@Observable
final class BotPlayer {

    private let engineManager: EngineManager

    /// Whether the bot is currently "thinking" about its next move.
    /// Drive a small activity indicator in ``GameView`` with this.
    private(set) var isThinking = false

    /// Set once the engine turns out to be unusable (e.g. a missing or
    /// corrupt NNUE network), so the bot will never move.
    private(set) var isEngineUnavailable = false

    /// Range (in seconds) of the minimum time the bot takes to reply, so
    /// it doesn't answer instantly. Engine thinking time counts toward it.
    private static let minimumReplyDelay: ClosedRange<Double> = 0.5...1.2

    init(engineManager: EngineManager) {
        self.engineManager = engineManager
    }

    /// Asks the engine for a move given the moves played so far (in
    /// engine LAN form), the legal moves in the current position (see
    /// ``ChessGame/legalEngineMoves``) and the bot's difficulty. With
    /// `allowCareless` off, the engine always plays its own best move.
    ///
    /// - returns: The chosen move in LAN form (e.g. `"e2e4"`), or `nil`
    /// if the engine couldn't produce one.
    func chooseMove(
        movesFromStart moves: [String],
        legalMoves: Set<String>,
        difficulty: BotDifficulty,
        allowCareless: Bool = true
    ) async -> String? {
        isThinking = true
        defer { isThinking = false }
        let start = ContinuousClock.now
        let minimumDelay = Duration.seconds(Double.random(in: Self.minimumReplyDelay))
        let move = await engineManager.bestMove(
            movesFromStart: moves,
            legalMoves: legalMoves,
            difficulty: difficulty,
            allowCareless: allowCareless
        )
        if move == nil, !(await engineManager.isAvailable) {
            isEngineUnavailable = true
        }
        let remaining = minimumDelay - (ContinuousClock.now - start)
        if move != nil, remaining > .zero {
            try? await Task.sleep(for: remaining)
        }
        return move
    }
}
