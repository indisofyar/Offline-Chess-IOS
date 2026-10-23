//
//  AnalysisView.swift
//  Offline Chess
//

import SwiftUI
import ChessKit
import Foundation

/// Shows a per-move quality breakdown and overall accuracy for a
/// finished game, gated behind ``AnalysisUsageTracker``'s free daily
/// limit (unlimited for premium users via ``PurchaseManager``).
struct AnalysisView: View {
    @Environment(AppState.self) private var appState

    let record: CompletedGameRecord

    @State private var analysisResult: AnalysisResult?
    @State private var isAnalyzing = false
    @State private var analysisProgress: Double = 0
    @State private var showPaywall = false

    init(record: CompletedGameRecord, previewResult: AnalysisResult? = nil) {
        self.record = record
        _analysisResult = State(initialValue: previewResult)
    }

    private var isPremium: Bool { appState.purchaseManager.isPremium }
    private var canAnalyze: Bool { appState.usageTracker.canUseAnalysis(isPremium: isPremium) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryHeader

                if let result = analysisResult {
                    accuracySummary(result)
                    moveBreakdown(result)
                } else if isAnalyzing {
                    analyzingCard
                } else if canAnalyze {
                    startCard
                } else {
                    lockedCard
                }
            }
            .padding()
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 6) {
            Text(record.resultDescription)
                .font(.headline)
            Text(record.date, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var startCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 36))
                .foregroundStyle(Color.chessAccent)

            Text("Get a full move-by-move breakdown and an accuracy score for both sides, powered by Stockfish running on your device.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if !isPremium {
                Text("\(appState.usageTracker.remainingFreeToday) free analysis remaining today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await runAnalysis() }
            } label: {
                Label("Run Analysis", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var analyzingCard: some View {
        VStack(spacing: 12) {
            ProgressView(value: analysisProgress)
                .tint(.chessAccent)
                .animation(.easeOut(duration: 0.2), value: analysisProgress)
            HStack {
                Text("Analyzing with Stockfish…")
                Spacer()
                Text(String(format: "%.0f%%", analysisProgress * 100))
                    .monospacedDigit()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.vertical, 24)
    }

    private var lockedCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("You've used today's free analysis.")
                .font(.headline)

            Text("Come back tomorrow, or go Premium for unlimited analyses.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showPaywall = true
            } label: {
                Label("Go Premium", systemImage: "crown.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.chessGold)
        }
        .padding()
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func accuracySummary(_ result: AnalysisResult) -> some View {
        HStack(spacing: 12) {
            StatTile(
                icon: "circle",
                title: "White accuracy",
                value: String(format: "%.0f%%", result.whiteAccuracy),
                color: .chessAccent
            )
            StatTile(
                icon: "circle.fill",
                title: "Black accuracy",
                value: String(format: "%.0f%%", result.blackAccuracy),
                color: .chessAccent
            )
        }
    }

    private func moveBreakdown(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Move by move")

            ForEach(result.moves) { move in
                VStack(spacing: 0) {
                    HStack {
                        Text("\(move.ply).")
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)
                        Text(move.color == .white ? "White" : "Black")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .leading)
                        Text(move.san)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        if move.centipawnLoss > 0 {
                            Text("-\(move.centipawnLoss)cp")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        JudgmentBadge(judgment: move.judgment)
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
    }

    private func runAnalysis() async {
        guard canAnalyze else { return }
        analysisProgress = 0
        isAnalyzing = true
        defer { isAnalyzing = false }

        if !isPremium {
            appState.usageTracker.recordUsage()
        }

        let service = AnalysisService(engineManager: appState.engineManager)
        analysisResult = await service.analyze(moves: record.moves) { progress in
            analysisProgress = progress
        }
    }
}

#Preview("Analysis - Start") {
    NavigationStack {
        AnalysisView(record: .preview)
            .environment(AppState())
    }
}

#Preview("Analysis - Results") {
    NavigationStack {
        AnalysisView(record: .preview, previewResult: .preview)
            .environment(AppState())
    }
}

extension CompletedGameRecord {
    static var preview: CompletedGameRecord {
        // Built on a plain `Board` rather than a throwaway `ChessGame`: releasing
        // a main-actor class right here, inside preview rendering, crashes in the
        // Swift runtime's back-deployed isolated-deinit path on iOS 18.
        var board = Board()
        let squares: [(Square, Square)] = [(.e2, .e4), (.e7, .e5), (.g1, .f3), (.b8, .c6), (.f1, .c4), (.f8, .c5)]
        let moves = squares.compactMap { board.move(pieceAt: $0.0, to: $0.1) }
        return CompletedGameRecord(
            moves: moves,
            resultDescription: "Checkmate — White wins",
            mode: .onePlayer,
            botDifficulty: .intermediate,
            date: Date()
        )
    }
}

extension AnalysisResult {
    static var preview: AnalysisResult {
        let record = CompletedGameRecord.preview
        let judgments: [MoveJudgment] = [.best, .excellent, .best, .good, .brilliant, .inaccuracy]
        let moves = record.moves.enumerated().map { index, move in
            MoveAnalysis(
                ply: index + 1,
                color: move.piece.color,
                san: move.san,
                judgment: judgments[index % judgments.count],
                centipawnLoss: [0, 8, 0, 18, 0, 40][index % 6]
            )
        }
        return AnalysisResult(moves: moves, whiteAccuracy: 92, blackAccuracy: 81)
    }
}
