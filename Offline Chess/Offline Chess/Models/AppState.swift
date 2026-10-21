//
//  AppState.swift
//  Offline Chess
//

import Foundation

/// App-wide shared state: the engine, store and usage services, the
/// user's chosen board skin / last difficulty, and the most recently
/// completed game (for the "Analyze last game" flow).
@MainActor
@Observable
final class AppState {

    let engineManager = EngineManager()
    let purchaseManager = PurchaseManager()
    let usageTracker = AnalysisUsageTracker()

    private(set) var boardSkin: BoardSkin
    private(set) var lastDifficulty: BotDifficulty
    var lastCompletedGame: CompletedGameRecord?

    private let defaults = UserDefaults.standard
    private let skinKey = "settings.boardSkin"
    private let difficultyKey = "settings.difficulty"

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
    }

    func updateBoardSkin(_ skin: BoardSkin) {
        boardSkin = skin
        defaults.set(skin.rawValue, forKey: skinKey)
    }

    func updateLastDifficulty(_ difficulty: BotDifficulty) {
        lastDifficulty = difficulty
        defaults.set(difficulty.rawValue, forKey: difficultyKey)
    }
}
