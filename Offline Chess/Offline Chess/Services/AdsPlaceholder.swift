//
//  AdsPlaceholder.swift
//  Offline Chess
//

import SwiftUI

/// A clearly-labelled placeholder banner shown to non-premium users in
/// place of a real ad SDK.
///
/// Integrating an actual third-party ad network is out of scope for
/// this MVP; this view marks where that would go and gives free users
/// a reason to see the paywall.
struct BannerAdPlaceholderView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("ADVERTISEMENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Text("Go Premium to remove ads")
                    .font(.footnote)
                    .fontWeight(.medium)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.appControlBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .foregroundStyle(.secondary.opacity(0.35))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Advertisement placeholder. Go premium to remove ads.")
    }
}

#Preview("Ad Placeholder") {
    BannerAdPlaceholderView()
        .padding()
}
