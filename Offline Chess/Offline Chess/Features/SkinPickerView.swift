//
//  SkinPickerView.swift
//  Offline Chess
//

import SwiftUI

/// Lets the player choose a board color palette, applied everywhere a
/// board is shown.
struct SkinPickerView: View {
    @Environment(AppState.self) private var appState

    private let columns = [GridItem(.adaptive(minimum: 88), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(BoardSkin.allCases) { skin in
                    Button {
                        appState.updateBoardSkin(skin)
                    } label: {
                        SkinSwatchView(skin: skin, isSelected: appState.boardSkin == skin)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Board Skin")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Skin Picker") {
    NavigationStack {
        SkinPickerView()
            .environment(AppState())
    }
}
