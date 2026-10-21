//
//  BotPlayer.swift
//  Offline Chess
//

import Foundation

/// Picks moves on behalf of the bot side of a 1-player game, using
/// ``EngineManager`` configured to the selected ``BotDifficulty``.
@MainActor
@Observable
final class BotPlayer {

    private let engineManager: EngineManager

    /// Whether the bot is currently "thinking" about its next move.
    /// Drive a small activity indicator in ``GameView`` with this.
    private(set) var isThinking = false

    init(engineManager: EngineManager) {
        self.engineManager = engineManager
    }

    /// Asks the engine for a move given the moves played so far (in
    /// engine LAN form) and the bot's difficulty.
    ///
    /// - returns: The chosen move in LAN form (e.g. `"e2e4"`), or `nil`
    /// if the engine couldn't produce one.
    func chooseMove(movesFromStart moves: [String], difficulty: BotDifficulty) async -> String? {
        isThinking = true
        defer { isThinking = false }
        return await engineManager.bestMove(movesFromStart: moves, difficulty: difficulty)
    }
}
