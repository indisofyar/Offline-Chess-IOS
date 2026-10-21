//
//  GameMode.swift
//  Offline Chess
//

import Foundation
import ChessKit

/// Whether a game is played against the bot or as local pass-and-play.
enum GameMode: String, Codable {
    case onePlayer
    case twoPlayer
}

/// The settings needed to start a new game, used to drive navigation
/// from ``HomeView`` to ``GameView``.
struct GameConfig: Hashable, Identifiable {
    let id = UUID()
    let mode: GameMode
    var humanColor: Piece.Color = .white
    var difficulty: BotDifficulty = .intermediate

    static func == (lhs: GameConfig, rhs: GameConfig) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
