import Foundation
import SwiftUI
import Combine

// ============================================================
// MARK: - Transaction Review Engine
// ============================================================
//
// Deterministic, explainable transaction review system.
//
// Detection Rules (all transparent):
//
// 1. UNCATEGORIZED: Transaction category == .other with non-empty note
//    → Suggest category based on keyword matching against note text
//    → Priority: medium (high if amount > 3x average)
//
// 2. POSSIBLE DUPLICATE: Same amount, same day (or ±1 day),
//    similar note (Levenshtein distance ≤ 30% of length)
//    → Priority: high
//
// 3. SPENDING SPIKE: Transaction amount > 3x the rolling 3-month
//    average for that category
//    → Priority: medium (high if > 5x average)
//
// 4. RECURRING CANDIDATE: 3+ transactions to same merchant with
//    roughly equal intervals (±5 days) that aren't already in
//    recurring transactions
//    → Priority: low
//
// 5. MERCHANT NORMALIZATION: Same merchant appears with multiple
//    name variants (case differences, trailing numbers, etc.)
//    → Priority: low
//
// ============================================================

@MainActor
class ReviewEngine: ObservableObject {

    static let shared = ReviewEngine()

    @Published var items: [ReviewItem] = []
    @Published var isLoading = false
    @Published var lastAnalyzedAt: Date?

    // Dismissed item IDs persist so they don't reappear
    private var dismissedTransactionKeys: Set<String> = []

    private init() {}

    // MARK: - Summary Stats

    var pendingCount: Int {
        items.filter { $0.status == .pending }.count
    }

    var highPriorityCount: Int {
        items.filter { $0.status == .pending && $0.priority == .high }.count
    }

    var uncategorizedCount: Int {
        items.filter { $0.status == .pending && $0.type == .uncategorized }.count
    }

    var duplicateCount: Int {
        items.filter { $0.status == .pending && $0.type == .possibleDuplicate }.count
    }

    var pendingItems: [ReviewItem] {
        items
            .filter { $0.status == .pending }
            .sorted { $0.priority > $1.priority }
    }

    func pendingByType(_ type: ReviewType) -> [ReviewItem] {
        items.filter { $0.status == .pending && $0.type == type }
    }

    // MARK: - Main Analysis

    func analyze(store: Store) async {
        isLoading = true

        let transactions = store.transactions
        let recurring = store.recurringTransactions

        let result = await Task.detached(priority: .userInitiated) {
            Self.detect(transactions: transactions, recurringTransactions: recurring)
        }.value

        // Merge: keep manually resolved items, replace pending auto-detected ones
        let resolvedIds = Set(items.filter { $0.status != .pending }.map { $0.id })
        let resolvedItems = items.filter { resolvedIds.contains($0.id) }

        // Filter out items for transactions the user already dismissed
        let newItems = result.filter { item in
            let key = item.transactionIds.map { $0.uuidString }.sorted().joined(separator: "|")
            return !dismissedTransactionKeys.contains(key)
        }

        self.items = resolvedItems + newItems
        self.lastAnalyzedAt = Date()
        self.isLoading = false
    }

    // MARK: - Actions

    /// Resolve an item (action was taken)
    func resolve(_ item: ReviewItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].status = .resolved
        items[idx].resolvedAt = Date()
    }

    /// Dismiss an item (user says it's fine)
    func dismiss(_ item: ReviewItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].status = .dismissed
        items[idx].resolvedAt = Date()

        // Remember this so it doesn't reappear
        let key = item.transactionIds.map { $0.uuidString }.sorted().joined(separator: "|")
        dismissedTransactionKeys.insert(key)
    }

    /// Assign category to a transaction
    func assignCategory(item: ReviewItem, category: Category, store: inout Store) {
        for txId in item.transactionIds {
            if let idx = store.transactions.firstIndex(where: { $0.id == txId }) {
                store.transactions[idx].category = category
                store.transactions[idx].lastModified = Date()
            }
        }
        resolve(item)
    }

    /// Mark transactions as duplicates (remove all but the first)
    func markDuplicate(item: ReviewItem, store: inout Store) {
        // Keep the first transaction, remove the rest
        let idsToRemove = Array(item.transactionIds.dropFirst())
        for txId in idsToRemove {
            store.transactions.removeAll { $0.id == txId }
            store.deletedTransactionIds.append(txId.uuidString)
        }
        resolve(item)
    }

    /// Create a recurring transaction from a candidate
    func createRecurring(item: ReviewItem, store: inout Store) {
        guard let firstTxId = item.transactionIds.first,
              let tx = store.transactions.first(where: { $0.id == firstTxId }) else {
            resolve(item)
            return
        }

        let recurring = RecurringTransaction(
            name: tx.note.isEmpty ? tx.category.title : tx.note,
            amount: tx.amount,
            category: tx.category,
            frequency: .monthly,
            startDate: tx.date,
            paymentMethod: tx.paymentMethod
        )

        store.recurringTransactions.append(recurring)
        resolve(item)
    }

    /// Normalize merchant names across transactions
    func normalizeMerchant(item: ReviewItem, normalizedName: String, store: inout Store) {
        for txId in item.transactionIds {
            if let idx = store.transactions.firstIndex(where: { $0.id == txId }) {
                store.transactions[idx].note = normalizedName
                store.transactions[idx].lastModified = Date()
            }
        }
        resolve(item)
    }

    // MARK: - Pure Detection (off main thread)

    nonisolated static func detect(
        transactions: [Transaction],
        recurringTransactions: [RecurringTransaction]
    ) -> [ReviewItem] {
        var items: [ReviewItem] = []

        let cal = Calendar.current
        let now = Date()
        // Focus on last 6 months for relevance
        let sixMonthsAgo = cal.date(byAdding: .month, value: -6, to: now)!
        let recent = transactions.filter { $0.date >= sixMonthsAgo }

        // ─── Rule 1: Uncategorized ───
        items.append(contentsOf: detectUncategorized(recent))

        // ─── Rule 2: Possible Duplicates ───
        items.append(contentsOf: detectDuplicates(recent))

        // ─── Rule 3: Spending Spikes ───
        items.append(contentsOf: detectSpikes(recent, cal: cal))

        // ─── Rule 4: Recurring Candidates ───
        items.append(contentsOf: detectRecurringCandidates(recent, existing: recurringTransactions, cal: cal))

        // ─── Rule 5: Merchant Normalization ───
        items.append(contentsOf: detectMerchantIssues(recent))

        return items
    }

    // MARK: Rule 1: Uncategorized

    nonisolated private static func detectUncategorized(_ transactions: [Transaction]) -> [ReviewItem] {
        var items: [ReviewItem] = []

        let uncategorized = transactions.filter { tx in
            tx.category == .other && tx.type == .expense && !tx.note.trimmingCharacters(in: .whitespaces).isEmpty
        }

        let avgExpense: Int = {
            let expenses = transactions.filter { $0.type == .expense }
            guard !expenses.isEmpty else { return 0 }
            return expenses.reduce(0) { $0 + $1.amount } / expenses.count
        }()

        for tx in uncategorized {
            let suggested = suggestCategory(from: tx.note)
            let isLarge = avgExpense > 0 && tx.amount > avgExpense * 3
            let priority: ReviewPriority = isLarge ? .high : .medium

            items.append(ReviewItem(
                transactionIds: [tx.id],
                type: .uncategorized,
                priority: priority,
                reason: "Transaction '\(tx.note)' is categorized as Other" + (suggested != nil ? ". Suggested: \(suggested!.title)" : ""),
                suggestedAction: .assignCategory,
                merchantName: tx.note,
                suggestedCategory: suggested
            ))
        }

        return items
    }

    /// Keyword-based category suggestion
    nonisolated private static func suggestCategory(from note: String) -> Category? {
        let lower = note.lowercased()

        let keywords: [(Category, [String])] = [
            (.groceries, ["grocery", "supermarket", "lidl", "aldi", "albert heijn", "jumbo", "coop", "rewe", "edeka", "market", "food"]),
            (.rent, ["rent", "housing", "mortgage", "landlord", "huur"]),
            (.bills, ["electric", "water", "gas", "internet", "phone", "mobile", "utility", "insurance", "netflix", "spotify", "subscription"]),
            (.transport, ["uber", "lyft", "taxi", "fuel", "petrol", "gas station", "parking", "train", "bus", "ov-chipkaart", "ns ", "transit"]),
            (.health, ["pharmacy", "doctor", "hospital", "dentist", "apotheek", "medical", "gym", "fitness"]),
            (.education, ["tuition", "course", "book", "udemy", "school", "university", "college", "training"]),
            (.dining, ["restaurant", "cafe", "coffee", "starbucks", "mcdonald", "burger", "pizza", "takeout", "takeaway", "deliveroo", "uber eats", "thuisbezorgd"]),
            (.shopping, ["amazon", "bol.com", "zalando", "h&m", "zara", "clothing", "electronics", "ikea", "store", "shop"])
        ]

        for (category, words) in keywords {
            for word in words {
                if lower.contains(word) {
                    return category
                }
            }
        }

        return nil
    }

    // MARK: Rule 2: Possible Duplicates

    nonisolated private static func detectDuplicates(_ transactions: [Transaction]) -> [ReviewItem] {
        var items: [ReviewItem] = []
        var processed = Set<UUID>()
        let cal = Calendar.current

        let sorted = transactions.sorted { $0.date < $1.date }

        for i in 0..<sorted.count {
            guard !processed.contains(sorted[i].id) else { continue }

            var group: [Transaction] = [sorted[i]]

            for j in (i+1)..<sorted.count {
                guard !processed.contains(sorted[j].id) else { continue }

                // Same amount
                guard sorted[i].amount == sorted[j].amount else { continue }

                // Same day or ±1 day
                let daysDiff = abs(cal.dateComponents([.day], from: sorted[i].date, to: sorted[j].date).day ?? 99)
                guard daysDiff <= 1 else { continue }

                // Similar note (at least one non-empty, and similar)
                if !sorted[i].note.isEmpty && !sorted[j].note.isEmpty {
                    let similarity = stringSimilarity(sorted[i].note, sorted[j].note)
                    guard similarity >= 0.7 else { continue }
                }

                // Same type
                guard sorted[i].type == sorted[j].type else { continue }

                group.append(sorted[j])
            }

            if group.count >= 2 {
                let ids = group.map { $0.id }
                ids.forEach { processed.insert($0) }
                let groupId = UUID()
                let names = group.map { $0.note.isEmpty ? $0.category.title : $0.note }
                let nameStr = names.first ?? "transaction"

                items.append(ReviewItem(
                    transactionIds: ids,
                    type: .possibleDuplicate,
                    priority: .high,
                    reason: "\(group.count) charges of €\(String(format: "%.2f", Double(group[0].amount) / 100.0)) for '\(nameStr)' on the same day",
                    suggestedAction: .markDuplicate,
                    duplicateGroupId: groupId
                ))
            }
        }

        return items
    }

    /// Normalized string similarity (0.0 = different, 1.0 = identical)
    nonisolated private static func stringSimilarity(_ a: String, _ b: String) -> Double {
        let s1 = a.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let s2 = b.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if s1 == s2 { return 1.0 }
        let maxLen = max(s1.count, s2.count)
        guard maxLen > 0 else { return 1.0 }
        let dist = levenshtein(s1, s2)
        return 1.0 - (Double(dist) / Double(maxLen))
    }

    /// Simple Levenshtein distance
    nonisolated private static func levenshtein(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count

        if m == 0 { return n }
        if n == 0 { return m }

        var prev = Array(0...n)
        var curr = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = a[i-1] == b[j-1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,       // deletion
                    curr[j-1] + 1,     // insertion
                    prev[j-1] + cost   // substitution
                )
            }
            prev = curr
        }

        return prev[n]
    }

    // MARK: Rule 3: Spending Spikes

    nonisolated private static func detectSpikes(_ transactions: [Transaction], cal: Calendar) -> [ReviewItem] {
        var items: [ReviewItem] = []

        let expenses = transactions.filter { $0.type == .expense }

        // Group by category
        var byCategory: [String: [Transaction]] = [:]
        for tx in expenses {
            byCategory[tx.category.storageKey, default: []].append(tx)
        }

        for (_, txs) in byCategory {
            guard txs.count >= 3 else { continue }

            let amounts = txs.map { $0.amount }
            let sorted = amounts.sorted()

            // Use trimmed mean (drop top/bottom 10%) for more robust average
            let trimCount = max(1, sorted.count / 10)
            let trimmed = Array(sorted.dropFirst(trimCount).dropLast(trimCount))
            let avg = trimmed.isEmpty ? (sorted.reduce(0, +) / sorted.count) : (trimmed.reduce(0, +) / trimmed.count)

            guard avg > 0 else { continue }

            for tx in txs {
                let ratio = Double(tx.amount) / Double(avg)
                if ratio >= 3.0 {
                    let priority: ReviewPriority = ratio >= 5.0 ? .high : .medium

                    items.append(ReviewItem(
                        transactionIds: [tx.id],
                        type: .spendingSpike,
                        priority: priority,
                        reason: "€\(String(format: "%.2f", Double(tx.amount) / 100.0)) is \(String(format: "%.1f", ratio))x the average for \(tx.category.title)",
                        suggestedAction: .reviewAmount,
                        spikeAmount: tx.amount,
                        spikeAverage: avg
                    ))
                }
            }
        }

        return items
    }

    // MARK: Rule 4: Recurring Candidates

    nonisolated private static func detectRecurringCandidates(
        _ transactions: [Transaction],
        existing: [RecurringTransaction],
        cal: Calendar
    ) -> [ReviewItem] {
        var items: [ReviewItem] = []

        let expenses = transactions.filter { $0.type == .expense && !$0.note.trimmingCharacters(in: .whitespaces).isEmpty }

        // Group by normalized note
        var byNote: [String: [Transaction]] = [:]
        for tx in expenses {
            let key = tx.note.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            byNote[key, default: []].append(tx)
        }

        // Names already in recurring
        let existingNames = Set(existing.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })

        for (name, txs) in byNote {
            guard txs.count >= 3 else { continue }
            guard !existingNames.contains(name) else { continue }

            let sorted = txs.sorted { $0.date < $1.date }

            // Check interval regularity
            var intervals: [Int] = []
            for i in 1..<sorted.count {
                let days = cal.dateComponents([.day], from: sorted[i-1].date, to: sorted[i].date).day ?? 0
                intervals.append(days)
            }

            guard !intervals.isEmpty else { continue }

            let medianInterval = median(intervals)
            guard medianInterval >= 5 else { continue } // at least weekly

            // Check regularity: intervals within ±5 days of median
            let regularCount = intervals.filter { abs($0 - medianInterval) <= 5 }.count
            let regularity = Double(regularCount) / Double(intervals.count)
            guard regularity >= 0.6 else { continue }

            // Check amount consistency
            let amounts = sorted.map { $0.amount }
            let avgAmount = amounts.reduce(0, +) / amounts.count
            let consistent = amounts.filter { abs($0 - avgAmount) <= avgAmount / 4 }.count // within 25%
            let amountConsistency = Double(consistent) / Double(amounts.count)
            guard amountConsistency >= 0.5 else { continue }

            let merchantDisplay = sorted.last?.note ?? name
            let cycleName: String
            if medianInterval <= 9 { cycleName = "weekly" }
            else if medianInterval <= 35 { cycleName = "monthly" }
            else if medianInterval <= 100 { cycleName = "quarterly" }
            else { cycleName = "periodic" }

            items.append(ReviewItem(
                transactionIds: sorted.map { $0.id },
                type: .recurringCandidate,
                priority: .low,
                reason: "'\(merchantDisplay)' appears \(sorted.count) times with a ~\(cycleName) pattern (avg €\(String(format: "%.2f", Double(avgAmount) / 100.0)))",
                suggestedAction: .createRecurring,
                merchantName: merchantDisplay
            ))
        }

        return items
    }

    // MARK: Rule 5: Merchant Normalization

    nonisolated private static func detectMerchantIssues(_ transactions: [Transaction]) -> [ReviewItem] {
        var items: [ReviewItem] = []

        let withNotes = transactions.filter { !$0.note.trimmingCharacters(in: .whitespaces).isEmpty }

        // Group by aggressive normalization (lowercase, remove trailing digits/special chars)
        var groups: [String: [String: [Transaction]]] = [:]  // normalized -> original -> txs
        for tx in withNotes {
            let original = tx.note.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = aggressiveNormalize(original)
            guard !normalized.isEmpty else { continue }
            groups[normalized, default: [:]][original, default: []].append(tx)
        }

        for (_, variants) in groups {
            guard variants.count >= 2 else { continue }

            // Multiple different spellings of the same merchant
            let allTxs = variants.values.flatMap { $0 }
            guard allTxs.count >= 3 else { continue }

            // Find the most common variant as the suggestion
            let mostCommon = variants.max(by: { $0.value.count < $1.value.count })!
            let variantNames = variants.keys.sorted()

            items.append(ReviewItem(
                transactionIds: allTxs.map { $0.id },
                type: .merchantNormalization,
                priority: .low,
                reason: "'\(variantNames.joined(separator: "', '"))' appear to be the same merchant. Suggested: '\(mostCommon.key)'",
                suggestedAction: .mergeMerchant,
                merchantName: mostCommon.key
            ))
        }

        return items
    }

    /// Aggressively normalize: lowercase, remove trailing digits, trim punctuation
    nonisolated private static func aggressiveNormalize(_ name: String) -> String {
        var result = name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove trailing digits and special chars (e.g., "Netflix #123" → "netflix")
        result = result.replacingOccurrences(of: "[#*0-9]+$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)

        // Collapse multiple spaces
        let parts = result.split(separator: " ").map(String.init)
        return parts.joined(separator: " ")
    }

    nonisolated private static func median(_ values: [Int]) -> Int {
        let sorted = values.sorted()
        let count = sorted.count
        if count == 0 { return 0 }
        if count % 2 == 0 { return (sorted[count/2 - 1] + sorted[count/2]) / 2 }
        return sorted[count/2]
    }
}
