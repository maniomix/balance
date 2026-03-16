import SwiftUI

// ============================================================
// MARK: - Review Dashboard Card
// ============================================================
//
// Compact dashboard card showing transaction review summary.
// Shows pending count, high-priority alerts, and quick link.
// ============================================================

struct ReviewDashboardCard: View {
    @Binding var store: Store
    @StateObject private var engine = ReviewEngine.shared
    @State private var showReviewQueue = false

    var body: some View {
        if engine.pendingCount > 0 {
            DS.Card {
                VStack(alignment: .leading, spacing: 10) {
                    // Header
                    HStack {
                        Image(systemName: "tray")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DS.Colors.warning)

                        Text("Needs Review")
                            .font(DS.Typography.section)
                            .foregroundStyle(DS.Colors.text)

                        Spacer()

                        Button {
                            showReviewQueue = true
                            Haptics.medium()
                        } label: {
                            Text("Review All")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.Colors.accent)
                        }
                    }

                    // Summary counts
                    HStack(spacing: 12) {
                        reviewStat(
                            count: engine.pendingCount,
                            label: "Items",
                            color: DS.Colors.accent
                        )

                        if engine.highPriorityCount > 0 {
                            reviewStat(
                                count: engine.highPriorityCount,
                                label: "Urgent",
                                color: DS.Colors.danger
                            )
                        }

                        if engine.uncategorizedCount > 0 {
                            reviewStat(
                                count: engine.uncategorizedCount,
                                label: "Uncategorized",
                                color: DS.Colors.warning
                            )
                        }

                        if engine.duplicateCount > 0 {
                            reviewStat(
                                count: engine.duplicateCount,
                                label: "Duplicates",
                                color: DS.Colors.danger
                            )
                        }

                        Spacer()
                    }

                    // Top priority items preview (up to 2)
                    let topItems = engine.pendingItems.prefix(2)
                    ForEach(Array(topItems)) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.type.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(item.type.color)
                                .frame(width: 16)

                            Text(item.reason)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(DS.Colors.text)
                                .lineLimit(1)

                            Spacer()

                            Text(item.priority.displayName)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(item.priority.color)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(item.priority.color.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
            .sheet(isPresented: $showReviewQueue) {
                ReviewQueueView(store: $store)
            }
        }
    }

    private func reviewStat(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DS.Colors.subtext)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08), in: Capsule())
    }
}
