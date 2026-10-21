//
//  SettingsView.swift
//  Offline Chess
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showPaywall = false

    var body: some View {
        List {
            Section("Board") {
                NavigationLink {
                    SkinPickerView()
                } label: {
                    HStack {
                        Text("Board Skin")
                        Spacer()
                        Text(appState.boardSkin.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Premium") {
                if appState.purchaseManager.isPremium {
                    Label("Premium unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Color.chessGold)
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        Label("Remove ads & unlock analysis", systemImage: "crown.fill")
                    }

                    Button("Restore Purchases") {
                        Task { await appState.purchaseManager.restore() }
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
                Text("Offline Chess plays entirely on-device — no network connection is ever required to play or analyze a game.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
            .environment(AppState())
    }
}
