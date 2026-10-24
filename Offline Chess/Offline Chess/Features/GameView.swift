//
//  GameView.swift
//  Offline Chess
//

import SwiftUI
import Foundation
import ChessKit

/// Hosts the board, turn indicator, move list, resign/draw controls and
/// promotion picker for a single game, driving bot moves asynchronously
/// on the bot's turn in 1-player mode.
struct GameView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var game: ChessGame
    @State private var botPlayer: BotPlayer?
    @State private var showResignConfirm = false
    @State private var navigateToAnalysis = false

    private let isRandomSide: Bool

    init(config: GameConfig) {
        isRandomSide = config.isRandomSide
        _game = State(
            initialValue: ChessGame(
                mode: config.mode,
                humanColor: config.humanColor,
                botDifficulty: config.difficulty,
                replaying: config.resumeMoves
            )
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            BoardView(game: game, skin: appState.boardSkin)
                .padding(.horizontal)
            moveList
            controls
        }
        .padding(.vertical)
        .navigationTitle(game.mode == .onePlayer ? "vs \(game.botDifficulty.displayName)" : "Pass & Play")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: GameTaskKey(game: ObjectIdentifier(game), moveCount: game.moveHistory.count)) {
            if botPlayer == nil {
                botPlayer = BotPlayer(engineManager: appState.engineManager)
            }
            if game.isGameOver {
                recordCompletedGame()
            } else {
                saveInProgressGame()
                await maybeMakeBotMove()
            }
        }
        .sheet(isPresented: promotionSheetBinding) {
            promotionPicker
                .presentationDetents([.height(220)])
        }
        .overlay {
            if let result = game.result {
                GameOverCard(
                    result: result,
                    outcome: GameOverCard.Outcome(result: result, game: game),
                    moveCount: game.moveHistory.count,
                    onPlayAgain: playAgain,
                    onAnalyze: { navigateToAnalysis = true },
                    onMainMenu: { dismiss() }
                )
            }
        }
        .navigationDestination(isPresented: $navigateToAnalysis) {
            if let record = appState.lastCompletedGame {
                AnalysisView(record: record)
            }
        }
        .confirmationDialog("Resign this game?", isPresented: $showResignConfirm, titleVisibility: .visible) {
            Button("Resign", role: .destructive) {
                game.resign(as: game.sideToMove)
                recordCompletedGame()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    /// Re-runs the game loop when a move is played or the game is
    /// replaced by Play Again, even if the move count is unchanged.
    private struct GameTaskKey: Equatable {
        let game: ObjectIdentifier
        let moveCount: Int
    }

    /// Starts a fresh game with the same mode, difficulty and colour,
    /// or a newly flipped colour if the side was picked at random.
    private func playAgain() {
        game = ChessGame(
            mode: game.mode,
            humanColor: isRandomSide ? SideChoice.random.resolvedColor() : game.humanColor,
            botDifficulty: game.botDifficulty
        )
    }

    private var promotionSheetBinding: Binding<Bool> {
        Binding(get: { game.pendingPromotion != nil }, set: { _ in })
    }

    private var header: some View {
        HStack {
            Label(
                game.sideToMove == .white ? "White to move" : "Black to move",
                systemImage: "circle.fill"
            )
            .font(.subheadline)
            .foregroundStyle(game.sideToMove == .white ? Color.primary : Color.secondary)

            Spacer()

            if botPlayer?.isEngineUnavailable == true {
                Label("Bot engine unavailable", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if botPlayer?.isThinking == true {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Thinking…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var moveList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(movePairs, id: \.number) { pair in
                    HStack(spacing: 4) {
                        Text("\(pair.number).")
                            .foregroundStyle(.secondary)
                        Text(pair.white)
                        if let black = pair.black {
                            Text(black)
                        }
                    }
                    .font(.system(.footnote, design: .monospaced))
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 20)
    }

    private struct MovePair {
        let number: Int
        let white: String
        let black: String?
    }

    private var movePairs: [MovePair] {
        var pairs: [MovePair] = []
        let san = game.sanMoves
        var i = 0
        while i < san.count {
            let number = i / 2 + 1
            let white = san[i]
            let black = (i + 1 < san.count) ? san[i + 1] : nil
            pairs.append(MovePair(number: number, white: white, black: black))
            i += 2
        }
        return pairs
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(role: .destructive) {
                showResignConfirm = true
            } label: {
                Label("Resign", systemImage: "flag.fill")
            }
            .disabled(game.isGameOver)

            Button {
                game.agreeToDraw()
                recordCompletedGame()
            } label: {
                Label("Offer Draw", systemImage: "hand.raised.fill")
            }
            .disabled(game.isGameOver || game.mode == .onePlayer)
        }
        .buttonStyle(.bordered)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var promotionPicker: some View {
        if let move = game.pendingPromotion {
            VStack(spacing: 16) {
                Text("Promote pawn to:")
                    .font(.headline)
                HStack(spacing: 20) {
                    ForEach([Piece.Kind.queen, .rook, .bishop, .knight], id: \.self) { kind in
                        Button {
                            game.completePromotion(to: kind)
                        } label: {
                            PieceGlyphView(piece: Piece(kind, color: move.piece.color, square: move.end), size: 40, skin: appState.boardSkin)
                                .padding(10)
                                .background(Color.appControlBackground, in: Circle())
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func maybeMakeBotMove() async {
        guard game.mode == .onePlayer,
            !game.isGameOver,
            game.pendingPromotion == nil,
            game.sideToMove != game.humanColor,
            let botPlayer
        else { return }

        // The engine skips stray replies that aren't legal here, but ask
        // again if a move still can't be applied rather than leaving the
        // bot stuck without a move.
        for attempt in 0..<Self.botMoveAttempts {
            guard let lan = await botPlayer.chooseMove(
                    movesFromStart: game.lanMoves,
                    legalMoves: game.legalEngineMoves,
                    difficulty: game.botDifficulty,
                    allowCareless: attempt == 0
                ),
                !Task.isCancelled
            else { return }

            if game.applyEngineMove(lan: lan) { return }
        }
    }

    private static let botMoveAttempts = 3

    /// Saves an unfinished bot game so it can be resumed from the home
    /// screen. Nothing is saved until the first move is played, so just
    /// opening a new game doesn't overwrite a previously saved one.
    private func saveInProgressGame() {
        guard game.mode == .onePlayer, !game.isGameOver, !game.moveHistory.isEmpty else { return }
        appState.saveBotGame(
            SavedBotGame(
                lanMoves: game.lanMoves,
                humanPlaysWhite: game.humanColor == .white,
                difficulty: game.botDifficulty,
                date: Date()
            )
        )
    }

    private func recordCompletedGame() {
        guard let result = game.result else { return }
        if game.mode == .onePlayer {
            appState.clearSavedBotGame()
        }
        appState.lastCompletedGame = CompletedGameRecord(
            moves: game.moveHistory,
            resultDescription: result.description,
            mode: game.mode,
            botDifficulty: game.mode == .onePlayer ? game.botDifficulty : nil,
            date: Date()
        )
    }
}

private struct GameOverCard: View {
    /// How the game ended from the player's point of view, which sets
    /// the card's tone: a celebration for a win, encouragement otherwise.
    enum Outcome: Equatable {
        /// The human beat the bot.
        case victory(BotDifficulty)
        /// The bot beat the human.
        case defeat(BotDifficulty)
        /// A pass-and-play game won by one side.
        case sideWins(Piece.Color)
        case draw

        @MainActor
        init(result: GameResult, game: ChessGame) {
            switch (result.winner, game.mode) {
            case (nil, _):
                self = .draw
            case let (winner?, .onePlayer):
                self = winner == game.humanColor ? .victory(game.botDifficulty) : .defeat(game.botDifficulty)
            case let (winner?, .twoPlayer):
                self = .sideWins(winner)
            }
        }

        var isCelebration: Bool {
            switch self {
            case .victory, .sideWins: true
            case .defeat, .draw: false
            }
        }
    }

    let result: GameResult
    let outcome: Outcome
    let moveCount: Int
    let onPlayAgain: () -> Void
    let onAnalyze: () -> Void
    let onMainMenu: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    var body: some View {
        ZStack {
            Color.black.opacity(isShown ? 0.3 : 0)
                .ignoresSafeArea()

            if outcome.isCelebration && !reduceMotion {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            card
                .scaleEffect(isShown || reduceMotion ? 1 : 0.85)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                isShown = true
            }
        }
        .sensoryFeedback(outcome.isCelebration ? .success : .impact(weight: .light), trigger: isShown) { _, shown in
            shown
        }
    }

    private var card: some View {
        VStack(spacing: 16) {
            badge

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(titleStyle)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if case let .victory(difficulty) = outcome {
                HStack(spacing: 8) {
                    statPill(icon: "star.fill", text: "Beat \(difficulty.targetRating)")
                    statPill(icon: "clock.fill", text: "\(fullMoves) moves")
                }
            }

            VStack(spacing: 10) {
                Button(action: onPlayAgain) {
                    Label(playAgainTitle, systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(outcome.isCelebration ? Color.chessGold : Color.chessAccent)

                Button(action: onAnalyze) {
                    Label(analyseTitle, systemImage: "chart.bar.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onMainMenu) {
                    Label("Main Menu", systemImage: "house.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            if outcome.isCelebration {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.chessGold.opacity(0.6), lineWidth: 2)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        .padding(32)
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(badgeTint.gradient)
                .frame(width: 84, height: 84)
                .shadow(color: badgeTint.opacity(0.5), radius: outcome.isCelebration ? 16 : 0)
            Image(systemName: badgeIcon)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, options: .repeat(2), value: isShown)
        }
        .accessibilityHidden(true)
    }

    private func statPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(Color.chessGold)
            .background(Color.chessGold.opacity(0.15), in: Capsule())
    }

    /// Moves counted the way chess players count them (one per pair).
    private var fullMoves: Int {
        (moveCount + 1) / 2
    }

    private var title: String {
        switch outcome {
        case .victory: "You Won!"
        case .defeat: "Good Game"
        case let .sideWins(color): color == .white ? "White Wins!" : "Black Wins!"
        case .draw: "It's a Draw"
        }
    }

    private var titleStyle: AnyShapeStyle {
        outcome.isCelebration
            ? AnyShapeStyle(LinearGradient(colors: [Color.chessGold, .orange], startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(.primary)
    }

    private var subtitle: String {
        switch (outcome, result.reason) {
        case let (.victory(difficulty), .checkmate):
            "You checkmated the \(difficulty.displayName) bot"
        case let (.victory(difficulty), _):
            "The \(difficulty.displayName) bot resigned"
        case let (.defeat(difficulty), .checkmate):
            "The \(difficulty.displayName) bot found checkmate"
        case let (.defeat(difficulty), _):
            "You resigned against the \(difficulty.displayName) bot"
        default:
            result.description
        }
    }

    private var message: String {
        switch outcome {
        case .victory:
            Self.victoryCheers[moveCount % Self.victoryCheers.count]
        case .defeat:
            "Every loss makes you sharper. Analyse the game to spot the turning point."
        case .sideWins:
            "What a game! Congratulations to the winner."
        case .draw:
            "A hard-fought battle with nothing to separate you."
        }
    }

    private static let victoryCheers = [
        "Brilliant play. That was a masterclass!",
        "Outstanding! The board was yours.",
        "Superb technique. You made that look easy!",
        "What a finish. You earned this one!",
    ]

    private var playAgainTitle: String {
        if case .defeat = outcome { "Rematch" } else { "Play Again" }
    }

    private var analyseTitle: String {
        outcome.isCelebration ? "Relive the Game" : "Analyse"
    }

    private var badgeIcon: String {
        switch outcome {
        case .victory, .sideWins: "trophy.fill"
        case .defeat: "arrow.up.heart.fill"
        case .draw: "equal"
        }
    }

    private var badgeTint: Color {
        switch outcome {
        case .victory, .sideWins: .chessGold
        case .defeat: .chessAccent
        case .draw: .gray
        }
    }
}

/// A short burst of falling confetti drawn with a ``Canvas`` so it stays
/// cheap however many pieces there are.
private struct ConfettiView: View {
    private struct Confetto {
        let x: Double
        let delay: Double
        let speed: Double
        let drift: Double
        let spin: Double
        let size: CGSize
        let color: Color
    }

    private static let colors: [Color] = [.chessGold, .chessAccent, .orange, .pink, .blue, .yellow, .mint]
    private static let duration: Double = 4.5

    private static func makeConfetti() -> [Confetto] {
        (0..<90).map { index in
            Confetto(
                x: .random(in: 0...1),
                delay: .random(in: 0...0.9),
                speed: .random(in: 0.22...0.42),
                drift: .random(in: -40...40),
                spin: .random(in: 2...7) * (index.isMultiple(of: 2) ? 1 : -1),
                size: CGSize(width: .random(in: 6...10), height: .random(in: 10...16)),
                color: colors[index % colors.count]
            )
        }
    }

    @State private var confetti = Self.makeConfetti()
    @State private var start = Date()
    @State private var isFinished = false

    var body: some View {
        if !isFinished {
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(start)
                Canvas { context, size in
                    for confetto in confetti {
                        let t = elapsed - confetto.delay
                        guard t > 0 else { continue }
                        let y = -20 + t * confetto.speed * size.height
                        guard y < size.height + 20 else { continue }
                        let x = confetto.x * size.width + sin(t * 2 + confetto.x * 10) * confetto.drift

                        var pieceContext = context
                        pieceContext.opacity = min(1, max(0, Self.duration - t))
                        pieceContext.translateBy(x: x, y: y)
                        pieceContext.rotate(by: .radians(t * confetto.spin))
                        // Squash horizontally over time so pieces look like they flutter.
                        pieceContext.scaleBy(x: cos(t * confetto.spin * 0.8), y: 1)
                        let rect = CGRect(
                            x: -confetto.size.width / 2,
                            y: -confetto.size.height / 2,
                            width: confetto.size.width,
                            height: confetto.size.height
                        )
                        pieceContext.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(confetto.color))
                    }
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(Self.duration + 1))
                isFinished = true
            }
        }
    }
}

#Preview("Game - Pass & Play") {
    NavigationStack {
        GameView(config: GameConfig(mode: .twoPlayer))
            .environment(AppState())
    }
}

#Preview("Game - vs Bot") {
    NavigationStack {
        GameView(config: GameConfig(mode: .onePlayer, humanColor: .white, difficulty: .advanced))
            .environment(AppState())
    }
}

#Preview("Game Over - Victory") {
    GameOverCard(
        result: GameResult(winner: .white, reason: .checkmate),
        outcome: .victory(.advanced),
        moveCount: 47,
        onPlayAgain: {},
        onAnalyze: {},
        onMainMenu: {}
    )
}

#Preview("Game Over - Defeat") {
    GameOverCard(
        result: GameResult(winner: .black, reason: .checkmate),
        outcome: .defeat(.advanced),
        moveCount: 52,
        onPlayAgain: {},
        onAnalyze: {},
        onMainMenu: {}
    )
}

#Preview("Game Over - Draw") {
    GameOverCard(
        result: GameResult(winner: nil, reason: .stalemate),
        outcome: .draw,
        moveCount: 80,
        onPlayAgain: {},
        onAnalyze: {},
        onMainMenu: {}
    )
}
