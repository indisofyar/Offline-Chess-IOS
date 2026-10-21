//
//  AnalysisUsageTracker.swift
//  Offline Chess
//

import Foundation

/// Tracks how many post-game analyses a free user has run today.
///
/// Free users get one analysis per calendar day; premium users
/// (``PurchaseManager/isPremium``) are unlimited. State is persisted in
/// `UserDefaults` so the daily limit survives app relaunches.
@MainActor
@Observable
final class AnalysisUsageTracker {

    let freeDailyLimit = 1

    private let defaults: UserDefaults
    private let lastUsedDateKey = "analysis.lastUsedDate"
    private let usageCountKey = "analysis.usageCount"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    /// How many analyses have been used today.
    var usedToday: Int {
        guard defaults.string(forKey: lastUsedDateKey) == todayKey else { return 0 }
        return defaults.integer(forKey: usageCountKey)
    }

    /// How many free analyses remain today.
    var remainingFreeToday: Int {
        max(0, freeDailyLimit - usedToday)
    }

    func canUseAnalysis(isPremium: Bool) -> Bool {
        isPremium || usedToday < freeDailyLimit
    }

    /// Records that an analysis was just run (rolling the counter over
    /// if it's a new day).
    func recordUsage() {
        if defaults.string(forKey: lastUsedDateKey) != todayKey {
            defaults.set(todayKey, forKey: lastUsedDateKey)
            defaults.set(0, forKey: usageCountKey)
        }
        defaults.set(usedToday + 1, forKey: usageCountKey)
    }
}
