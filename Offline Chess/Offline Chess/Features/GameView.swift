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

    init(config: GameConfig) {
        _game = State(
            initialValue: ChessGame(
                mode: config.mode,
                humanColor: config.humanColor,
                botDifficulty: config.difficulty
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
        .task(id: game.moveHistory.count) {
            if botPlayer == nil {
                botPlayer = BotPlayer(engineManager: appState.engineManager)
            }
            if game.isGameOver {
                recordCompletedGame()
            } else {
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
                    onAnalyze: { navigateToAnalysis = true },
                    onDone: { dismiss() }
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

        if let lan = await botPlayer.chooseMove(movesFromStart: game.lanMoves, difficulty: game.botDifficulty) {
            game.applyEngineMove(lan: lan)
        }
    }

    private func recordCompletedGame() {
        guard let result = game.result else { return }
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
    let result: GameResult
    let onAnalyze: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Game Over")
                .font(.title2.bold())
            Text(result.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button(action: onAnalyze) {
                    Label("Analyze Game", systemImage: "chart.bar.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onDone) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(32)
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
