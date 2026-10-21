//
//  BotDifficulty.swift
//  Offline Chess
//

import Foundation

/// A selectable bot strength, similar to chess.com's bot picker.
///
/// Each difficulty maps to a combination of Stockfish UCI options
/// (`UCI_LimitStrength` + `UCI_Elo`, or `Skill Level` for the very
/// weakest bots where Stockfish's Elo limiter has a higher floor
/// than we want) plus a search time budget so weaker bots also
/// "think" for a shorter, more human amount of time.
enum BotDifficulty: String, CaseIterable, Identifiable, Codable {
    case beginner
    case easy
    case intermediate
    case advanced
    case expert
    case master

    var id: String { rawValue }

    /// Approximate real-world rating this bot targets.
    var targetRating: Int {
        switch self {
        case .beginner: 800
        case .easy: 1000
        case .intermediate: 1300
        case .advanced: 1600
        case .expert: 1900
        case .master: 2200
        }
    }

    var displayName: String {
        switch self {
        case .beginner: "Beginner"
        case .easy: "Easy"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        case .expert: "Expert"
        case .master: "Master"
        }
    }

    var subtitle: String {
        "~\(targetRating) rating"
    }

    var icon: String {
        switch self {
        case .beginner: "tortoise.fill"
        case .easy: "figure.walk"
        case .intermediate: "figure.run"
        case .advanced: "bolt.fill"
        case .expert: "flame.fill"
        case .master: "crown.fill"
        }
    }

    /// Stockfish's `UCI_Elo` option only goes down to about 1320, so
    /// below that we clamp `Skill Level` (0-20) instead and leave
    /// `UCI_LimitStrength` off.
    var usesSkillLevel: Bool {
        targetRating < 1320
    }

    /// Value for the `Skill Level` UCI option (0-20), used for the
    /// weakest bots.
    var skillLevel: Int {
        switch self {
        case .beginner: 1
        case .easy: 3
        default: 20
        }
    }

    /// Value for the `UCI_Elo` UCI option, clamped to Stockfish's
    /// supported 1320-3190 range.
    var uciElo: Int {
        min(max(targetRating, 1320), 3190)
    }

    /// How long (in milliseconds) the bot is allowed to think before
    /// replying, scaled so weaker bots move faster/less consistently
    /// and stronger bots take a bit longer to "look deeper".
    var moveTimeMillis: Int {
        switch self {
        case .beginner: 250
        case .easy: 350
        case .intermediate: 500
        case .advanced: 700
        case .expert: 1000
        case .master: 1500
        }
    }
}
