//
//  AnalysisBoardView.swift
//  Offline Chess
//

import SwiftUI
import ChessKit

/// A read-only board for stepping through an analyzed game. Swipe the
/// board left/right (or use the buttons) to move between positions; the
/// strip above the controls shows every move colored by its judgment,
/// and can be tapped or scrubbed to jump straight to a move.
struct AnalysisBoardView: View {
    /// One replayed game per position: index 0 is the starting position,
    /// index `n` is the position after ply `n`.
    let positions: [ChessGame]
    let moves: [MoveAnalysis]
    let skin: BoardSkin
    @Binding var ply: Int

    private var currentMove: MoveAnalysis? {
        ply > 0 && ply <= moves.count ? moves[ply - 1] : nil
    }

    /// Plies of moves worth reviewing: inaccuracies, mistakes and blunders.
    private var keyMomentPlies: [Int] {
        moves.filter { [.inaccuracy, .mistake, .blunder].contains($0.judgment) }.map(\.ply)
    }

    var body: some View {
        VStack(spacing: 12) {
            BoardView(game: positions[min(ply, positions.count - 1)], skin: skin)
                .allowsHitTesting(false)
                .overlay {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(swipeGesture)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Board")
                .accessibilityValue(currentMove.map { "Move \($0.ply), \($0.san), \($0.judgment.rawValue)" } ?? "Starting position")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: step(by: 1)
                    case .decrement: step(by: -1)
                    @unknown default: break
                    }
                }

            currentMoveRow

            if !moves.isEmpty {
                timeline
            }

            controls
        }
        .sensoryFeedback(.selection, trigger: ply)
    }

    // MARK: Subviews

    private var currentMoveRow: some View {
        HStack(spacing: 8) {
            if let move = currentMove {
                Text("\(move.ply).")
                    .foregroundStyle(.secondary)
                Text(move.color == .white ? "White" : "Black")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(move.san)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                Spacer()
                if move.centipawnLoss > 0 {
                    Text("-\(move.centipawnLoss)cp")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                JudgmentBadge(judgment: move.judgment)
            } else {
                Text("Starting position")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Swipe the board to step through")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 28)
    }

    /// Every move as a thin bar colored by its judgment; the current
    /// move is drawn taller and fully opaque.
    private var timeline: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: 1) {
                ForEach(moves) { move in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(Color.judgmentColor(move.judgment))
                        .opacity(move.ply == ply ? 1 : 0.4)
                        .frame(maxWidth: .infinity)
                        .frame(height: move.ply == ply ? 20 : 12)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = value.location.x / max(proxy.size.width, 1)
                        let index = Int((fraction * CGFloat(moves.count)).rounded(.down))
                        ply = min(max(index, 0), moves.count - 1) + 1
                    }
            )
        }
        .frame(height: 20)
        .animation(.easeOut(duration: 0.15), value: ply)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        HStack {
            controlButton("backward.end.fill", label: "First move") { ply = 0 }
                .disabled(ply == 0)
            controlButton("chevron.left", label: "Previous move") { step(by: -1) }
                .disabled(ply == 0)

            Button {
                jumpToNextKeyMoment()
            } label: {
                Label("Next mistake", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Color.judgmentColor(.mistake))
            .disabled(keyMomentPlies.isEmpty)

            controlButton("chevron.right", label: "Next move") { step(by: 1) }
                .disabled(ply == moves.count)
            controlButton("forward.end.fill", label: "Last move") { ply = moves.count }
                .disabled(ply == moves.count)
        }
    }

    private func controlButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(label)
    }

    // MARK: Navigation

    /// Swiping left moves forward through the game, like turning a page.
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let dx = value.translation.width
                guard abs(dx) > abs(value.translation.height), abs(dx) > 40 else { return }
                step(by: dx < 0 ? 1 : -1)
            }
    }

    private func step(by delta: Int) {
        ply = min(max(ply + delta, 0), moves.count)
    }

    /// Jumps to the next inaccuracy/mistake/blunder after the current
    /// move, wrapping back to the first one at the end of the game.
    private func jumpToNextKeyMoment() {
        guard let next = keyMomentPlies.first(where: { $0 > ply }) ?? keyMomentPlies.first else { return }
        ply = next
    }
}
