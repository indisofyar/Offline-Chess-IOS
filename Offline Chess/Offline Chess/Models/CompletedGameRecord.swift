//
//  CompletedGameRecord.swift
//  Offline Chess
//

import Foundation
import ChessKit

/// A lightweight snapshot of the most recently finished game, kept
/// around so "Analyze last game" has something to work with.
struct CompletedGameRecord {
    let moves: [Move]
    let resultDescription: String
    let mode: GameMode
    let botDifficulty: BotDifficulty?
    let date: Date

    var sanMoves: [String] { moves.map(\.san) }
    var lanMoves: [String] { moves.map(\.lan) }
}
