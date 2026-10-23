//
//  AppState.swift
//  Offline Chess
//

import Foundation
import Observation

/// App-wide shared state: the engine, store and usage services, the
/// user's chosen board skin / last difficulty / last side, and the most recently
/// completed game (for the "Analyze last game" flow), and any unfinished
/// bot game (for the "Continue Game" flow).
@MainActor
@Observable
final class AppState {

    let engineManager = EngineManager()
    let purchaseManager = PurchaseManager()
    let usageTracker = AnalysisUsageTracker()

    private(set) var boardSkin: BoardSkin
    private(set) var lastDifficulty: BotDifficulty
    private(set) var lastSideChoice: SideChoice
    var lastCompletedGame: CompletedGameRecord?
    /// Set via ``saveBotGame(_:)`` / ``clearSavedBotGame()`` to persist;
    /// assign directly only for in-memory use (e.g. previews).
    var savedBotGame: SavedBotGame?

    private let defaults = UserDefaults.standard
    private let skinKey = "settings.boardSkin"
    private let difficultyKey = "settings.difficulty"
    private let sideChoiceKey = "settings.sideChoice"
    private let savedBotGameKey = "game.savedBotGame"

    init() {
        if let raw = UserDefaults.standard.string(forKey: "settings.boardSkin"),
            let skin = BoardSkin(rawValue: raw) {
            boardSkin = skin
        } else {
            boardSkin = .classicGreen
        }

        if let raw = UserDefaults.standard.string(forKey: "settings.difficulty"),
            let difficulty = BotDifficulty(rawValue: raw) {
            lastDifficulty = difficulty
        } else {
            lastDifficulty = .intermediate
        }

        if let raw = UserDefaults.standard.string(forKey: "settings.sideChoice"),
            let side = SideChoice(rawValue: raw) {
            lastSideChoice = side
        } else {
            lastSideChoice = .white
        }

        if let data = UserDefaults.standard.data(forKey: "game.savedBotGame") {
            savedBotGame = try? JSONDecoder().decode(SavedBotGame.self, from: data)
        }
    }

    func updateBoardSkin(_ skin: BoardSkin) {
        boardSkin = skin
        defaults.set(skin.rawValue, forKey: skinKey)
    }

    func updateLastDifficulty(_ difficulty: BotDifficulty) {
        lastDifficulty = difficulty
        defaults.set(difficulty.rawValue, forKey: difficultyKey)
    }

    func updateLastSideChoice(_ side: SideChoice) {
        lastSideChoice = side
        defaults.set(side.rawValue, forKey: sideChoiceKey)
    }

    /// Persists an unfinished bot game so it can be resumed later.
    func saveBotGame(_ game: SavedBotGame) {
        savedBotGame = game
        if let data = try? JSONEncoder().encode(game) {
            defaults.set(data, forKey: savedBotGameKey)
        }
    }

    func clearSavedBotGame() {
        savedBotGame = nil
        defaults.removeObject(forKey: savedBotGameKey)
    }
}
