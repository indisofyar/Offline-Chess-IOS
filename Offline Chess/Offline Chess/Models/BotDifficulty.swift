//
//  BotDifficulty.swift
//  Offline Chess
//

import Foundation

/// A selectable bot strength, similar to chess.com's bot picker.
///
/// Each difficulty maps to a Stockfish `Skill Level` and `MultiPV`,
/// a chance of playing a random candidate move (for the weakest bots),
/// and a search time budget so weaker bots also "think" for a shorter,
/// more human amount of time.
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

    /// Value for Stockfish's `Skill Level` UCI option (0-20).
    ///
    /// Every bot uses `Skill Level` directly rather than `UCI_Elo`:
    /// Stockfish just converts `UCI_Elo` into a fractional skill level
    /// on a curve that puts even 2200 at about level 5, which made the
    /// Elo-limited bots weaker than Intermediate. Measured by self-play
    /// against a full-strength judge: average centipawn loss per move
    /// drops steadily from about 140 (Novice) to about 14 (Master).
    var skillLevel: Int {
        switch self {
        case .novice, .beginner, .casual: 0
        case .easy: 1
        case .club: 3
        case .intermediate: 5
        case .skilled: 7
        case .advanced: 9
        case .strong: 11
        case .expert: 13
        case .candidateMaster: 16
        case .master: 19
        }
    }

    /// Value for the `MultiPV` UCI option. A weak `Skill Level` picks
    /// its move from this many candidate lines (Stockfish uses at least
    /// 4), so more lines means more chances to choose a poor move.
    var multiPV: Int {
        switch self {
        case .novice: 20
        case .beginner: 14
        case .casual: 12
        case .easy: 6
        default: 1
        }
    }

    /// Chance (0-1) that the bot ignores Stockfish's pick and plays a
    /// random one of its candidate moves instead. Even `Skill Level` 0
    /// rarely hangs pieces, so this supplies the outright blunders a
    /// ~500-800 player makes.
    var carelessMoveChance: Double {
        switch self {
        case .novice: 0.45
        case .beginner: 0.35
        case .casual: 0.20
        case .easy: 0.03
        default: 0
        }
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
