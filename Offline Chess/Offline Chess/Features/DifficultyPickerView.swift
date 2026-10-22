//
//  DifficultyPickerView.swift
//  Offline Chess
//

import SwiftUI

/// Lets the player pick a bot strength before starting a 1-player
/// game, similar to chess.com's bot picker.
struct DifficultyPickerView: View {
    @State private var selected: BotDifficulty
    let onStart: (BotDifficulty) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(initialDifficulty: BotDifficulty, onStart: @escaping (BotDifficulty) -> Void) {
        _selected = State(initialValue: initialDifficulty)
        self.onStart = onStart
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    SectionHeader(
                        title: "Choose your opponent",
                        subtitle: "Each bot plays at a different target rating."
                    )
                    .padding(.bottom, 4)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(BotDifficulty.allCases) { difficulty in
                            Button {
                                selected = difficulty
                            } label: {
                                DifficultyTile(difficulty: difficulty, isSelected: selected == difficulty)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Difficulty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        onStart(selected)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview("Difficulty Picker") {
    DifficultyPickerView(initialDifficulty: .intermediate) { _ in }
}
