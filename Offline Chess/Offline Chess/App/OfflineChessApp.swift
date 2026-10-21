//
//  OfflineChessApp.swift
//  Offline Chess
//

import SwiftUI
import ChessKit

@main
struct OfflineChessApp: App {
    @State private var appState = AppState()

    init() {
        // Force ChessKit's `Attacks` lookup-table cache to populate here,
        // synchronously and single-threaded, before any concurrent code
        // path (e.g. the bot/analysis engine actor vs. the main-actor UI)
        // can construct a `Board()` at the same time. The cache's writes
        // are lock-protected but its reads aren't, so without this warm-up
        // a race during first use can corrupt the heap.
        _ = Board()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appState)
        }
    }
}
