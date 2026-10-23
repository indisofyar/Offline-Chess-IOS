//
//  SidePickerView.swift
//  Offline Chess
//

import SwiftUI

/// First step of starting a 1-player game: pick White, Black or a random
/// side, then continue to ``DifficultyPickerView`` to pick the bot.
struct SidePickerView: View {
    @State private var selected: SideChoice
    @State private var chosenSide: SideChoice?
    let initialDifficulty: BotDifficulty
    let onStart: (SideChoice, BotDifficulty) -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        initialSide: SideChoice,
        initialDifficulty: BotDifficulty,
        onStart: @escaping (SideChoice, BotDifficulty) -> Void
    ) {
        _selected = State(initialValue: initialSide)
        self.initialDifficulty = initialDifficulty
        self.onStart = onStart
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    SectionHeader(
                        title: "Choose your side",
                        subtitle: "White moves first. The board turns so your pieces are at the bottom."
                    )
                    .padding(.bottom, 4)

                    ForEach(SideChoice.allCases) { side in
                        Button {
                            selected = side
                            chosenSide = side
                        } label: {
                            SideRow(side: side, isSelected: selected == side)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Play vs Bot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(item: $chosenSide) { side in
                DifficultyPickerView(initialDifficulty: initialDifficulty) { difficulty in
                    onStart(side, difficulty)
                }
            }
        }
    }
}

private struct SideRow: View {
    let side: SideChoice
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            swatch
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(side.displayName)
                    .font(.headline)
                Text(side.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? Color.chessAccent : .clear, lineWidth: 2)
        }
    }

    /// A white, black, or half-and-half square for the side.
    private var swatch: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return ZStack {
            switch side {
            case .white:
                shape.fill(Color.white)
            case .black:
                shape.fill(Color.black)
            case .random:
                shape.fill(
                    LinearGradient(
                        stops: [.init(color: .white, location: 0.5), .init(color: .black, location: 0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                Image(systemName: "shuffle")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.chessAccent)
            }
        }
        .overlay {
            shape.strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1)
        }
    }
}

#Preview("Side Picker") {
    SidePickerView(initialSide: .white, initialDifficulty: .intermediate) { _, _ in }
}
