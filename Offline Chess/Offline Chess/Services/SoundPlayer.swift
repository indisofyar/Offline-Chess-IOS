//
//  SoundPlayer.swift
//  Offline Chess
//

import AVFoundation
import ChessKit

/// Plays the board sound effects. Players are preloaded so each sound
/// starts instantly, and the `.ambient` session category respects the
/// silent switch and mixes with any music already playing.
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

    private var players: [Effect: AVAudioPlayer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)

        for effect in Effect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[effect] = player
        }
    }

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    func play(_ effect: Effect) {
        guard isEnabled, let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    /// Plays the sound that matches `move`: castling, a capture or a
    /// plain move, voiced by the color of the side that moved.
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
