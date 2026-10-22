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
    case novice
    case beginner
    case casual
    case easy
    case club
    case intermediate
    case skilled
    case advanced
    case strong
    case expert
    case candidateMaster
    case master

    var id: String { rawValue }

    /// Approximate real-world rating this bot targets.
    var targetRating: Int {
        switch self {
        case .novice: 500
        case .beginner: 650
        case .casual: 800
        case .easy: 950
        case .club: 1100
        case .intermediate: 1250
        case .skilled: 1400
        case .advanced: 1550
        case .strong: 1700
        case .expert: 1850
        case .candidateMaster: 2000
        case .master: 2200
        }
    }

    var displayName: String {
        switch self {
        case .novice: "Novice"
        case .beginner: "Beginner"
        case .casual: "Casual"
        case .easy: "Easy"
        case .club: "Club"
        case .intermediate: "Intermediate"
        case .skilled: "Skilled"
        case .advanced: "Advanced"
        case .strong: "Strong"
        case .expert: "Expert"
        case .candidateMaster: "Candidate Master"
        case .master: "Master"
        }
    }

    var subtitle: String {
        "~\(targetRating) rating"
    }

    var icon: String {
        switch self {
        case .novice: "leaf.fill"
        case .beginner: "tortoise.fill"
        case .casual: "figure.walk"
        case .easy: "hare.fill"
        case .club: "person.2.fill"
        case .intermediate: "figure.run"
        case .skilled: "star.fill"
        case .advanced: "bolt.fill"
        case .strong: "dumbbell.fill"
        case .expert: "flame.fill"
        case .candidateMaster: "medal.fill"
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
        case .novice: 0
        case .beginner: 1
        case .casual: 2
        case .easy: 3
        case .club: 5
        case .intermediate: 7
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
        case .novice: 200
        case .beginner: 250
        case .casual: 300
        case .easy: 350
        case .club: 400
        case .intermediate: 450
        case .skilled: 550
        case .advanced: 650
        case .strong: 750
        case .expert: 900
        case .candidateMaster: 1150
        case .master: 1500
        }
    }
}
