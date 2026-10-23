//
//  AnalysisService.swift
//  Offline Chess
//

import Foundation
import ChessKit

/// A single move's quality judgment, modeled after how chess.com /
/// lichess classify moves in post-game analysis.
enum MoveJudgment: String, CaseIterable {
    case brilliant = "Brilliant"
    case best = "Best"
    case excellent = "Excellent"
    case good = "Good"
    case inaccuracy = "Inaccuracy"
    case mistake = "Mistake"
    case blunder = "Blunder"

    var symbol: String {
        switch self {
        case .brilliant: "!!"
        case .best: "★"
        case .excellent: "!"
        case .good: "✓"
        case .inaccuracy: "?!"
        case .mistake: "?"
        case .blunder: "??"
        }
    }
}

/// The analysis result for a single played move.
struct MoveAnalysis: Identifiable {
    let id = UUID()
    let ply: Int
    let color: Piece.Color
    let san: String
    let judgment: MoveJudgment
    let centipawnLoss: Int
}

/// The full result of analyzing a finished game.
struct AnalysisResult {
    let moves: [MoveAnalysis]
    let whiteAccuracy: Double
    let blackAccuracy: Double
}

/// Runs Stockfish over every move of a finished game to classify move
/// quality and compute an overall accuracy percentage per side.
///
/// The approach: evaluate every position in the game (from the
/// perspective of whoever is to move there) at a fixed search depth,
/// then for each played move compare the evaluation before the move to
/// the evaluation after it (from the mover's point of view) to get a
/// centipawn loss, which is classified into a ``MoveJudgment``.
@MainActor
struct AnalysisService {

    private let engineManager: EngineManager

    init(engineManager: EngineManager) {
        self.engineManager = engineManager
    }

    /// Analyzes `moves` (in game order) and returns per-move judgments
    /// plus overall accuracy for each side. `onProgress` is called with a
    /// 0...1 fraction after each position is evaluated.
    func analyze(
        moves: [Move],
        depth: Int = 14,
        onProgress: (Double) -> Void = { _ in }
    ) async -> AnalysisResult {
        let lanMoves = moves.map(\.lan)

        var evaluations: [Double] = []
        var engineBestMoves: [String?] = []

        let totalPositions = lanMoves.count + 1
        onProgress(0)

        for ply in 0...lanMoves.count {
            let prefix = Array(lanMoves.prefix(ply))
            let evaluation = await engineManager.evaluate(movesFromStart: prefix, depth: depth)
            // Cap mate scores so missing a long mate doesn't register as
            // a loss of thousands of centipawns.
            evaluations.append(min(max(evaluation.centipawns, -Self.evaluationCap), Self.evaluationCap))
            engineBestMoves.append(evaluation.bestMove)
            onProgress(Double(ply + 1) / Double(totalPositions))
        }

        var analyses: [MoveAnalysis] = []
        var whiteAccuracies: [Double] = []
        var blackAccuracies: [Double] = []

        for i in 0..<moves.count {
            let move = moves[i]
            let moverColor = move.piece.color

            let evalBeforeForMover = evaluations[i]
            let evalAfterForOpponent = evaluations[i + 1]
            let evalAfterForMover = -evalAfterForOpponent

            let loss = max(0, evalBeforeForMover - evalAfterForMover)
            let playedEngineBest = engineBestMoves[i] == lanMoves[i]

            let judgment = classify(loss: loss, playedEngineBest: playedEngineBest, move: move)

            analyses.append(
                MoveAnalysis(
                    ply: i + 1,
                    color: moverColor,
                    san: move.san,
                    judgment: judgment,
                    centipawnLoss: Int(loss)
                )
            )

            let moveAccuracy = accuracy(
                winPercentBefore: winPercent(centipawns: evalBeforeForMover),
                winPercentAfter: winPercent(centipawns: evalAfterForMover)
            )
            if moverColor == .white {
                whiteAccuracies.append(moveAccuracy)
            } else {
                blackAccuracies.append(moveAccuracy)
            }
        }

        return AnalysisResult(
            moves: analyses,
            whiteAccuracy: average(whiteAccuracies),
            blackAccuracy: average(blackAccuracies)
        )
    }

    /// Evaluations are clamped to this many centipawns either way.
    private static let evaluationCap: Double = 1_000

    /// The mover's chance of winning (0-100) for an evaluation, using
    /// lichess's centipawn-to-win% curve.
    private func winPercent(centipawns: Double) -> Double {
        50 + 50 * (2 / (1 + exp(-0.00368208 * centipawns)) - 1)
    }

    /// A single move's 0-100% accuracy from how much it dropped the
    /// mover's win chance, using lichess's accuracy curve (which takes a
    /// win% drop, not a centipawn loss).
    private func accuracy(winPercentBefore: Double, winPercentAfter: Double) -> Double {
        let drop = max(0, winPercentBefore - winPercentAfter)
        let raw = 103.1668 * exp(-0.04354 * drop) - 3.1669
        return min(100, max(0, raw))
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 100 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func classify(loss: Double, playedEngineBest: Bool, move: Move) -> MoveJudgment {
        if playedEngineBest {
            return isLikelySacrifice(move) ? .brilliant : .best
        }

        switch loss {
        case ..<10: return .excellent
        case ..<25: return .good
        case ..<50: return .inaccuracy
        case ..<100: return .mistake
        default: return .blunder
        }
    }

    /// A simple, honest heuristic for a "brilliant" move: the engine's
    /// own top choice, and it wins material with a piece that's worth
    /// notably less than what it captured (e.g. a pawn or knight taking
    /// a queen), which usually indicates a tactic rather than a routine
    /// recapture.
    private func isLikelySacrifice(_ move: Move) -> Bool {
        guard case let .capture(capturedPiece) = move.result else { return false }
        return pieceValue(capturedPiece.kind) - pieceValue(move.piece.kind) >= 2
    }

    private func pieceValue(_ kind: Piece.Kind) -> Int {
        switch kind {
        case .pawn: 1
        case .knight, .bishop: 3
        case .rook: 5
        case .queen: 9
        case .king: 0
        }
    }
}
