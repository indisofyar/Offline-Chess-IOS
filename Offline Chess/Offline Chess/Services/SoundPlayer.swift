//
//  SoundPlayer.swift
//  Offline Chess
//

import AVFoundation
import ChessKit

/// Plays the board sound effects. Players are preloaded so each sound
/// starts instantly, and the `.ambient` session category respects the
/// silent switch and mixes with any music already playing.
///
/// Session activation blocks, and `AVAudioPlayer.play()` activates the
/// session implicitly, so all audio work runs on a private serial queue
/// instead of the main thread.
@MainActor
final class SoundPlayer {

    static let shared = SoundPlayer()

    /// `UserDefaults` key for the Settings sound toggle (defaults to on).
    static let enabledKey = "settings.soundEnabled"

    enum Effect: String, CaseIterable {
        case moveWhite = "move_white"
        case moveBlack = "move_black"
        case captureWhite = "capture_white"
        case captureBlack = "capture_black"
        case castle = "castle"
    }

    private let engine = Engine()

    private init() {
        engine.setUp()
    }

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    func play(_ effect: Effect) {
        guard isEnabled else { return }
        engine.play(effect)
    }

    /// Plays the sound that matches `move`: castling, a capture or a
    /// plain move, voiced by the colour of the side that moved.
    func play(for move: Move) {
        let isWhite = move.piece.color == .white

        switch move.result {
        case .castle:
            play(.castle)
        case .capture:
            play(isWhite ? .captureWhite : .captureBlack)
        case .move:
            play(isWhite ? .moveWhite : .moveBlack)
        }
    }
}

extension SoundPlayer {

    /// Owns the session and the players. `players` is only touched on
    /// `queue`, which is what makes the `@unchecked Sendable` safe.
    private nonisolated final class Engine: @unchecked Sendable {

        private let queue = DispatchQueue(label: "SoundPlayer.audio", qos: .userInitiated)
        private var players: [Effect: AVAudioPlayer] = [:]

        func setUp() {
            queue.async { [self] in
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.ambient)
                try? session.setActive(true)

                for effect in Effect.allCases {
                    guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
                          let player = try? AVAudioPlayer(contentsOf: url) else { continue }
                    player.prepareToPlay()
                    players[effect] = player
                }
            }
        }

        func play(_ effect: Effect) {
            queue.async { [self] in
                guard let player = players[effect] else { return }
                player.currentTime = 0
                player.play()
            }
        }
    }
}
