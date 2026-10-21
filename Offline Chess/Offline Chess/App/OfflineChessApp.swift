//
//  OfflineChessApp.swift
//  Offline Chess
//

import SwiftUI

@main
struct OfflineChessApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appState)
        }
    }
}
