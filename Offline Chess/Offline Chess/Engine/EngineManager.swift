//
//  EngineManager.swift
//  Offline Chess
//

import Foundation
import CryptoKit
import ChessKitEngine

/// Owns a single Stockfish ``Engine`` instance and serializes access to
/// it, since only one UCI request can be in flight at a time.
///
/// This type wraps the raw UCI protocol so the rest of the app never
/// talks to ``ChessKitEngine`` directly: ``BotPlayer`` uses it to pick
/// bot moves, and ``AnalysisService`` uses it to evaluate positions
/// after a game ends.
actor EngineManager {

    private let engine = Engine(type: .stockfish)
    private var hasStarted = false
    private var isBusy = false
    private var networksValid: Bool?

    /// The NNUE networks ``ChessKitEngine`` loads from the main bundle
    /// for Stockfish's `EvalFile` and `EvalFileSmall` options.
    private static let networkNames = ["nn-1111cefa1111", "nn-37f18f62d772"]

    /// Whether the engine can be used. `false` if a bundled NNUE network
    /// is missing or corrupt, in which case every request returns `nil`.
    var isAvailable: Bool {
        if let networksValid { return networksValid }
        let valid = Self.networkNames.allSatisfy(Self.isValidNetwork(named:))
        networksValid = valid
        return valid
    }

    /// Stockfish names each network `nn-<first 12 hex chars of its
    /// SHA-256>`, so a file whose hash doesn't match its name is the
    /// wrong network (or a Git LFS pointer) and must not be loaded:
    /// Stockfish calls `exit()` on the first `go` if a network fails
    /// to load, which kills the whole app.
    private static func isValidNetwork(named name: String) -> Bool {
        guard let url = Bundle.main.url(forResource: name, withExtension: "nnue"),
            let data = try? Data(contentsOf: url, options: .mappedIfSafe)
        else { return false }

        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return name == "nn-\(hash.prefix(12))"
    }

    /// Starts the engine (if needed) and waits until it has finished
    /// its internal UCI handshake and is ready to accept commands.
    ///
    /// - returns: `false` if the engine is unavailable.
    private func ensureStarted() async -> Bool {
        guard isAvailable else { return false }
        guard !hasStarted else { return true }

        await engine.start()

        while !(await engine.isRunning) {
            try? await Task.sleep(nanoseconds: 40_000_000)
        }

        hasStarted = true
        return true
    }

    /// Simple cooperative lock so bot-move requests and analysis
    /// requests never interleave on the same response stream.
    private func acquireTurn() async {
        while isBusy {
            try? await Task.sleep(nanoseconds: 15_000_000)
        }
        isBusy = true
    }

    private func releaseTurn() {
        isBusy = false
    }

    /// Search threads used for post-game analysis. Bot moves always
    /// search on one thread so bot strength doesn't vary by device.
    private static let analysisThreads = max(min(ProcessInfo.processInfo.activeProcessorCount - 1, 3), 1)

    /// Configures Stockfish's playing strength for the given difficulty.
    private func configureStrength(for difficulty: BotDifficulty) async {
        await engine.send(command: .setoption(id: "Threads", value: "1"))
        if difficulty.usesSkillLevel {
            await engine.send(command: .setoption(id: "UCI_LimitStrength", value: "false"))
            await engine.send(command: .setoption(id: "Skill Level", value: "\(difficulty.skillLevel)"))
        } else {
            await engine.send(command: .setoption(id: "UCI_LimitStrength", value: "true"))
            await engine.send(command: .setoption(id: "UCI_Elo", value: "\(difficulty.uciElo)"))
        }
    }

    /// Returns the engine's best move (in LAN form, e.g. `"e2e4"` or
    /// `"e7e8q"`) for the position reached by playing `moves` from the
    /// starting position, using the given bot `difficulty`.
    func bestMove(movesFromStart moves: [String], difficulty: BotDifficulty) async -> String? {
        guard await ensureStarted() else { return nil }
        await acquireTurn()
        defer { releaseTurn() }

        await configureStrength(for: difficulty)
        await engine.send(command: .position(.startpos, moves: moves))
        await engine.send(command: .go(movetime: difficulty.moveTimeMillis))

        guard let stream = await engine.responseStream else { return nil }

        for await response in stream {
            if case let .bestmove(move, _) = response {
                return move
            }
        }

        return nil
    }

    /// Evaluates the position reached by playing `moves` from the
    /// starting position at full strength and search `depth`.
    ///
    /// - returns: The evaluation in centipawns from the perspective of
    /// the side to move in that position (mate scores are converted to
    /// a large centipawn-equivalent value), along with the engine's
    /// best move from that position.
    func evaluate(movesFromStart moves: [String], depth: Int) async -> (centipawns: Double, bestMove: String?) {
        guard await ensureStarted() else { return (0, nil) }
        await acquireTurn()
        defer { releaseTurn() }

        await engine.send(command: .setoption(id: "Threads", value: "\(Self.analysisThreads)"))
        // Undo any bot weakening: `Skill Level` stays set after a
        // Beginner/Easy game and would make Stockfish pick weaker
        // "best" moves (and search 4 lines instead of 1).
        await engine.send(command: .setoption(id: "UCI_LimitStrength", value: "false"))
        await engine.send(command: .setoption(id: "Skill Level", value: "20"))
        await engine.send(command: .position(.startpos, moves: moves))
        await engine.send(command: .go(depth: depth))

        guard let stream = await engine.responseStream else { return (0, nil) }

        var lastScore: EngineResponse.Info.Score?

        for await response in stream {
            switch response {
            case let .info(info):
                if let score = info.score {
                    lastScore = score
                }
            case let .bestmove(move, _):
                return (Self.centipawns(from: lastScore), move)
            default:
                break
            }
        }

        return (0, nil)
    }

    private static func centipawns(from score: EngineResponse.Info.Score?) -> Double {
        guard let score else { return 0 }

        if let mate = score.mate {
            // Convert a "mate in N" score into a large centipawn-equivalent
            // value so it still sorts/compares sensibly against normal
            // centipawn scores.
            return mate > 0 ? (10_000 - Double(mate) * 10) : (-10_000 - Double(mate) * 10)
        }

        return score.cp ?? 0
    }
}
