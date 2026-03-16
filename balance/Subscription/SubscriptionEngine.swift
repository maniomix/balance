import Foundation
import SwiftUI
import Combine

// ============================================================
// MARK: - Subscription Detection Engine
// ============================================================
//
// Deterministic subscription detection from transaction history.
//
// Detection Strategy (all rules are transparent & explainable):
//
// 1. Group transactions by normalized merchant name
// 2. For each merchant group:
//    a. Check for regularity (consistent intervals: 7d, 30d, 365d)
//    b. Check for amount similarity (charges within 15% of median)
//    c. Require minimum 2 occurrences to flag
//    d. Assign confidence score based on match quality
// 3. Produce insight labels:
//    - Price increase: last charge > previous by >2%
//    - Upcoming renewal: within 7 days
//    - Maybe unused: >60 days without non-subscription transactions in same category
//    - Duplicate risk: multiple subscriptions in same category with similar amounts
//    - Missed charge: expected charge didn't appear within ±5 days of expected date
//
// ============================================================

@MainActor
class SubscriptionEngine: ObservableObject {

    static let shared = SubscriptionEngine()

    @Published var subscriptions: [DetectedSubscription] = []
    @Published var insights: [SubscriptionInsight] = []
    @Published var isLoading = false
    @Published var lastAnalyzedAt: Date?

    // Summary stats
    @Published var monthlyTotal: Int = 0
    @Published var yearlyTotal: Int = 0
    @Published var activeCount: Int = 0

    private init() {}

    // MARK: - Main Analysis

    /// Analyze transactions to detect and update subscriptions.
    /// Merges auto-detected subscriptions with manually-managed ones.
    func analyze(store: Store) async {
        isLoading = true

        let transactions = store.transactions
        let existing = subscriptions.filter { !$0.isAutoDetected }

        let result = await Task.detached(priority: .userInitiated) {
            Self.detect(transactions: transactions, existingManual: existing)
        }.value

        self.subscriptions = result.subscriptions
        self.insights = result.globalInsights
        self.monthlyTotal = result.subscriptions
            .filter { $0.status == .active }
            .reduce(0) { $0 + $1.monthlyCost }
        self.yearlyTotal = result.subscriptions
            .filter { $0.status == .active }
            .reduce(0) { $0 + $1.yearlyCost }
        self.activeCount = result.subscriptions.filter { $0.status == .active }.count
        self.lastAnalyzedAt = Date()
        self.isLoading = false
    }

    // MARK: - Manual Actions

    func markAsCancelled(_ sub: DetectedSubscription) {
        guard let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) else { return }
        subscriptions[idx].status = .cancelled
        subscriptions[idx].updatedAt = Date()
        recalcTotals()
    }

    func markAsPaused(_ sub: DetectedSubscription) {
        guard let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) else { return }
        subscriptions[idx].status = .paused
        subscriptions[idx].updatedAt = Date()
        recalcTotals()
    }

    func markAsActive(_ sub: DetectedSubscription) {
        guard let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) else { return }
        subscriptions[idx].status = .active
        subscriptions[idx].updatedAt = Date()
        recalcTotals()
    }

    func updateNotes(_ sub: DetectedSubscription, notes: String) {
        guard let idx = subscriptions.firstIndex(where: { $0.id == sub.id }) else { return }
        subscriptions[idx].notes = notes
        subscriptions[idx].updatedAt = Date()
    }

    func removeSubscription(_ sub: DetectedSubscription) {
        subscriptions.removeAll { $0.id == sub.id }
        recalcTotals()
    }

    private func recalcTotals() {
        monthlyTotal = subscriptions
            .filter { $0.status == .active }
            .reduce(0) { $0 + $1.monthlyCost }
        yearlyTotal = subscriptions
            .filter { $0.status == .active }
            .reduce(0) { $0 + $1.yearlyCost }
        activeCount = subscriptions.filter { $0.status == .active }.count
    }

    // MARK: - Subscriptions by next renewal

    var upcomingRenewals: [DetectedSubscription] {
        subscriptions
            .filter { $0.status == .active && $0.nextRenewalDate != nil }
            .sorted { ($0.nextRenewalDate ?? .distantFuture) < ($1.nextRenewalDate ?? .distantFuture) }
    }

    /// Subscriptions with insights attached
    func insightsFor(_ sub: DetectedSubscription) -> [SubscriptionInsight] {
        var labels: [SubscriptionInsight] = []

        if sub.hasPriceIncrease {
            labels.append(.priceIncreased)
        }
        if let days = sub.daysUntilRenewal, days <= 7, days >= 0 {
            labels.append(.upcomingRenewal)
        }
        if sub.status == .suspectedUnused {
            labels.append(.maybeUnused)
        }

        // Duplicate risk: another active subscription in same category with similar amount
        let sameCategory = subscriptions.filter {
            $0.id != sub.id &&
            $0.status == .active &&
            $0.category == sub.category
        }
        for other in sameCategory {
            let diff = abs(other.expectedAmount - sub.expectedAmount)
            let threshold = max(sub.expectedAmount, other.expectedAmount) / 4 // 25%
            if diff <= threshold {
                labels.append(.duplicateRisk)
                break
            }
        }

        return labels
    }

    // MARK: - Pure Detection Logic (off main thread)

    struct DetectionResult {
        let subscriptions: [DetectedSubscription]
        let globalInsights: [SubscriptionInsight]
    }

    nonisolated static func detect(
        transactions: [Transaction],
        existingManual: [DetectedSubscription]
    ) -> DetectionResult {
        let cal = Calendar.current
        let now = Date()

        // Only look at expenses
        let expenses = transactions.filter { $0.type == .expense }

        // ─── Step 1: Group by normalized merchant name ───

        let grouped = groupByMerchant(expenses)

        // ─── Step 2: Analyze each group ───

        var detected: [DetectedSubscription] = []

        for (merchant, txs) in grouped {
            guard txs.count >= 2 else { continue }

            // Sort by date ascending
            let sorted = txs.sorted { $0.date < $1.date }

            // ─── Step 2a: Compute intervals between charges ───

            var intervals: [Int] = []
            for i in 1..<sorted.count {
                let days = cal.dateComponents([.day], from: sorted[i-1].date, to: sorted[i].date).day ?? 0
                intervals.append(days)
            }

            guard !intervals.isEmpty else { continue }

            // ─── Step 2b: Detect billing cycle from intervals ───

            let medianInterval = median(intervals)
            let cycle = detectCycle(medianInterval: medianInterval)
            guard let billingCycle = cycle else { continue }

            // ─── Step 2c: Check interval regularity ───
            // Intervals should be within 30% of median to be considered regular

            let regularCount = intervals.filter { interval in
                let deviation = abs(interval - medianInterval)
                return Double(deviation) / Double(max(1, medianInterval)) <= 0.30
            }.count

            let regularityRatio = Double(regularCount) / Double(intervals.count)
            guard regularityRatio >= 0.5 else { continue } // At least 50% regular

            // ─── Step 2d: Check amount similarity ───

            let amounts = sorted.map { $0.amount }
            let medianAmount = medianInt(amounts)
            let similarCount = amounts.filter { amt in
                let deviation = abs(amt - medianAmount)
                return Double(deviation) / Double(max(1, medianAmount)) <= 0.15
            }.count

            let amountSimilarity = Double(similarCount) / Double(amounts.count)

            // ─── Step 2e: Compute confidence score ───

            var confidence = 0.0
            confidence += regularityRatio * 0.4     // 40% from interval regularity
            confidence += amountSimilarity * 0.3    // 30% from amount consistency
            confidence += min(1.0, Double(sorted.count) / 6.0) * 0.2  // 20% from occurrence count
            confidence += (billingCycle != .custom ? 0.1 : 0.0) // 10% from recognized cycle

            guard confidence >= 0.45 else { continue }

            // ─── Step 2f: Build subscription ───

            let lastTx = sorted.last!
            let lastAmount = lastTx.amount
            let nextRenewal = cal.date(byAdding: .day, value: billingCycle.approximateDays, to: lastTx.date)

            let chargeHistory = sorted.map { tx in
                ChargeRecord(transactionId: tx.id, amount: tx.amount, date: tx.date)
            }

            // Determine status
            var status: SubscriptionStatus = .active

            // If last charge was more than 2x the billing cycle ago, mark as maybe missed/unused
            let daysSinceLastCharge = cal.dateComponents([.day], from: lastTx.date, to: now).day ?? 0
            if daysSinceLastCharge > billingCycle.approximateDays * 2 {
                status = .suspectedUnused
            }

            let sub = DetectedSubscription(
                merchantName: merchant,
                category: sorted.last?.category ?? .bills,
                expectedAmount: medianAmount,
                lastAmount: lastAmount,
                billingCycle: billingCycle,
                nextRenewalDate: nextRenewal,
                lastChargeDate: lastTx.date,
                status: status,
                linkedTransactionIds: sorted.map { $0.id },
                isAutoDetected: true,
                confidenceScore: confidence,
                chargeHistory: chargeHistory
            )

            detected.append(sub)
        }

        // ─── Step 3: Merge with manual subscriptions ───

        var all = existingManual + detected

        // Sort by monthly cost descending
        all.sort { $0.monthlyCost > $1.monthlyCost }

        // ─── Step 4: Detect global insights ───

        var globalInsights: [SubscriptionInsight] = []

        // Any price increases?
        if all.contains(where: { $0.hasPriceIncrease }) {
            globalInsights.append(.priceIncreased)
        }

        // Any upcoming in 7 days?
        if all.contains(where: {
            guard let days = $0.daysUntilRenewal else { return false }
            return days <= 7 && days >= 0 && $0.status == .active
        }) {
            globalInsights.append(.upcomingRenewal)
        }

        // Any suspected unused?
        if all.contains(where: { $0.status == .suspectedUnused }) {
            globalInsights.append(.maybeUnused)
        }

        // Duplicate risk check
        let activeSubs = all.filter { $0.status == .active }
        var hasDuplicate = false
        for i in 0..<activeSubs.count {
            for j in (i+1)..<activeSubs.count {
                if activeSubs[i].category == activeSubs[j].category {
                    let diff = abs(activeSubs[i].expectedAmount - activeSubs[j].expectedAmount)
                    let threshold = max(activeSubs[i].expectedAmount, activeSubs[j].expectedAmount) / 4
                    if diff <= threshold {
                        hasDuplicate = true
                        break
                    }
                }
            }
            if hasDuplicate { break }
        }
        if hasDuplicate {
            globalInsights.append(.duplicateRisk)
        }

        return DetectionResult(subscriptions: all, globalInsights: globalInsights)
    }

    // MARK: - Helpers

    /// Group transactions by normalized merchant name.
    /// Uses note field as merchant name (the main descriptor in this app).
    nonisolated private static func groupByMerchant(_ transactions: [Transaction]) -> [String: [Transaction]] {
        var groups: [String: [Transaction]] = [:]

        for tx in transactions {
            let name = normalizeMerchant(tx.note)
            guard !name.isEmpty else { continue }
            groups[name, default: []].append(tx)
        }

        return groups
    }

    /// Normalize merchant name: lowercase, trim whitespace, collapse multiple spaces
    nonisolated private static func normalizeMerchant(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Collapse whitespace
        let components = trimmed.split(separator: " ").map(String.init)
        return components.joined(separator: " ")
    }

    /// Detect billing cycle from median interval in days
    nonisolated private static func detectCycle(medianInterval: Int) -> BillingCycle? {
        // Weekly: 5–9 days
        if medianInterval >= 5 && medianInterval <= 9 { return .weekly }
        // Monthly: 25–35 days
        if medianInterval >= 25 && medianInterval <= 35 { return .monthly }
        // Yearly: 340–395 days
        if medianInterval >= 340 && medianInterval <= 395 { return .yearly }
        // Custom: anything between weekly and yearly with some regularity
        if medianInterval >= 10 && medianInterval <= 339 { return .custom }
        return nil
    }

    /// Median of integer array
    nonisolated private static func median(_ values: [Int]) -> Int {
        let sorted = values.sorted()
        let count = sorted.count
        if count == 0 { return 0 }
        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2
        }
        return sorted[count/2]
    }

    /// Alias for amounts
    nonisolated private static func medianInt(_ values: [Int]) -> Int {
        median(values)
    }
}
