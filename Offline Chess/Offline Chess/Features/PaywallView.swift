//
//  PaywallView.swift
//  Offline Chess
//

import SwiftUI

/// Shows the real StoreKit product (price localized by the App Store)
/// for the one-time "unlock pro" purchase, plus restore.
struct PaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.chessGold)

                    Text("Offline Chess Premium")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "rectangle.slash", text: "No ads, ever")
                        FeatureRow(icon: "infinity", text: "Unlimited post-game analysis")
                        FeatureRow(icon: "checkmark.seal.fill", text: "One-time purchase, yours for life")
                    }
                    .padding()
                    .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if appState.purchaseManager.isPremium {
                        Label("You already own Premium", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            Task {
                                isPurchasing = true
                                await appState.purchaseManager.purchase()
                                isPurchasing = false
                                if appState.purchaseManager.isPremium {
                                    dismiss()
                                }
                            }
                        } label: {
                            if isPurchasing {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Unlock for \(appState.purchaseManager.priceText)")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.chessGold)
                        .disabled(isPurchasing)

                        Button("Restore Purchases") {
                            Task { await appState.purchaseManager.restore() }
                        }
                        .font(.footnote)
                    }

                    if let error = appState.purchaseManager.lastErrorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("Go Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.chessAccent)
                .frame(width: 24)
            Text(text)
            Spacer(minLength: 0)
        }
    }
}

#Preview("Paywall") {
    PaywallView()
        .environment(AppState())
}
