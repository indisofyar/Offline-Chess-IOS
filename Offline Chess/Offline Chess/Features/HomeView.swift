//
//  HomeView.swift
//  Offline Chess
//

import SwiftUI
import ChessKit

/// The root screen: pick 1-player/2-player, see the difficulty picker
/// for 1-player games, continue an unfinished bot game, jump into last
/// game's analysis, and reach
/// settings/skins/the paywall.
struct HomeView: View {
    @Environment(AppState.self) private var appState

    @State private var showDifficultyPicker = false
    @State private var showSettings = false
    @State private var activeGameConfig: GameConfig?
    @State private var navigateToAnalysis = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    VStack(spacing: 12) {
                        if let saved = appState.savedBotGame {
                            MenuCardButton(
                                icon: "play.fill",
                                title: "Continue Game",
                                subtitle: "vs \(saved.difficulty.displayName) · move \(saved.fullMoveCount)",
                                tint: .green
                            ) {
                                activeGameConfig = GameConfig(resuming: saved)
                            }
                        }

                        MenuCardButton(
                            icon: "cpu",
                            title: "Play vs Bot",
                            subtitle: "Choose a difficulty and play Stockfish",
                            tint: .chessAccent
                        ) {
                            showDifficultyPicker = true
                        }

                        MenuCardButton(
                            icon: "person.2.fill",
                            title: "Pass & Play",
                            subtitle: "Two players, one device",
                            tint: .brown
                        ) {
                            activeGameConfig = GameConfig(mode: .twoPlayer)
                        }

                        MenuCardButton(
                            icon: "chart.bar.fill",
                            title: "Analyze Last Game",
                            subtitle: appState.lastCompletedGame == nil
                                ? "Play a game first" : "Move-by-move breakdown",
                            tint: .purple
                        ) {
                            navigateToAnalysis = true
                        }
                        .opacity(appState.lastCompletedGame == nil ? 0.5 : 1)
                        .disabled(appState.lastCompletedGame == nil)
                    }
                }
                .padding()
            }
            .navigationTitle("Offline Chess")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showDifficultyPicker) {
                DifficultyPickerView(initialDifficulty: appState.lastDifficulty) { difficulty in
                    appState.updateLastDifficulty(difficulty)
                    activeGameConfig = GameConfig(mode: .onePlayer, humanColor: .white, difficulty: difficulty)
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showSettings = false }
                            }
                        }
                }
            }
            .navigationDestination(item: $activeGameConfig) { config in
                GameView(config: config)
            }
            .navigationDestination(isPresented: $navigateToAnalysis) {
                if let record = appState.lastCompletedGame {
                    AnalysisView(record: record)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("♞")
                .font(.system(size: 54))
            Text("Offline Chess")
                .font(.largeTitle.bold())
            Text("Chess and chess analysis without wifi")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

#Preview("Home") {
    HomeView()
        .environment(AppState())
}

#Preview("Home - With Saved Bot Game") {
    let state = AppState()
    state.savedBotGame = SavedBotGame(
        lanMoves: ["e2e4", "e7e5", "g1f3"],
        humanPlaysWhite: true,
        difficulty: .advanced,
        date: Date()
    )
    return HomeView()
        .environment(state)
}

#Preview("Home - With Last Game") {
    let state = AppState()
    state.lastCompletedGame = .preview
    return HomeView()
        .environment(state)
}
