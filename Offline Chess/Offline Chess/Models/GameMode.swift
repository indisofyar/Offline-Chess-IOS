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

/// Which side the human picks to play against the bot.
enum SideChoice: String, CaseIterable, Identifiable {
    case white
    case black
    case random

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .white: "White"
        case .black: "Black"
        case .random: "Random"
        }
    }

    var subtitle: String {
        switch self {
        case .white: "You move first"
        case .black: "The bot moves first"
        case .random: "Leave it to a coin flip"
        }
    }

    /// The colour to play: fixed for White/Black, a coin flip for Random.
    func resolvedColor() -> Piece.Color {
        switch self {
        case .white: .white
        case .black: .black
        case .random: Bool.random() ? .white : .black
        }
    }
}

/// The settings needed to start a new game, used to drive navigation
/// from ``HomeView`` to ``GameView``.
struct GameConfig: Hashable, Identifiable {
    let id = UUID()
    let mode: GameMode
    var humanColor: Piece.Color = .white
    var difficulty: BotDifficulty = .intermediate
    /// Moves (LAN) to replay before play begins, when resuming a saved game.
    var resumeMoves: [String] = []

    static func == (lhs: GameConfig, rhs: GameConfig) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension GameConfig {
    /// A config that resumes `saved` where it left off.
    init(resuming saved: SavedBotGame) {
        self.init(
            mode: .onePlayer,
            humanColor: saved.humanColor,
            difficulty: saved.difficulty,
            resumeMoves: saved.lanMoves
        )
    }
}
