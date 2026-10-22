//
//  SkinPickerView.swift
//  Offline Chess
//

import SwiftUI

/// Lets the player choose a board skin, applied everywhere a board is
/// shown. Picking a different skin switches to its default colour.
struct SkinPickerView: View {
    @Environment(AppState.self) private var appState

    private let columns = [GridItem(.adaptive(minimum: 88), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(BoardSkinFamily.allCases) { family in
                    let isSelected = appState.boardSkin.family == family
                    Button {
                        if !isSelected {
                            appState.updateBoardSkin(family.colors[0])
                        }
                    } label: {
                        SkinSwatchView(
                            skin: isSelected ? appState.boardSkin : family.colors[0],
                            isSelected: isSelected,
                            title: family.displayName
                        )
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

/// Lets the player choose a colour for the current board skin.
struct SkinColorPickerView: View {
    @Environment(AppState.self) private var appState

    private let columns = [GridItem(.adaptive(minimum: 88), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(appState.boardSkin.family.colors) { skin in
                    Button {
                        appState.updateBoardSkin(skin)
                    } label: {
                        SkinSwatchView(skin: skin, isSelected: appState.boardSkin == skin, title: skin.colorName)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Board Colour")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Skin Picker") {
    NavigationStack {
        SkinPickerView()
            .environment(AppState())
    }
}

#Preview("Skin Colour Picker") {
    NavigationStack {
        SkinColorPickerView()
            .environment(AppState())
    }
}
