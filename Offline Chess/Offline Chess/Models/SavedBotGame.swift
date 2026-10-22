//
//  SavedBotGame.swift
//  Offline Chess
//

import Foundation
import ChessKit

/// An unfinished 1-player game, persisted so it can be resumed from
/// the "Continue Game" button on ``HomeView``.
struct SavedBotGame: Codable, Equatable {
    /// Every move played so far, in engine LAN form (e.g. `"e2e4"`).
    let lanMoves: [String]
    let humanPlaysWhite: Bool
    let difficulty: BotDifficulty
    let date: Date

    var humanColor: Piece.Color { humanPlaysWhite ? .white : .black }

    /// Number of full moves played, for display.
    var fullMoveCount: Int { (lanMoves.count + 1) / 2 }
}
