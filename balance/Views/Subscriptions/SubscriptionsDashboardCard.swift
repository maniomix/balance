import SwiftUI

// ============================================================
// MARK: - Subscriptions Dashboard Card
// ============================================================
//
// Compact card for the main dashboard showing subscription
// summary: monthly total, active count, upcoming renewals,
// and insight warnings.
// ============================================================

struct SubscriptionsDashboardCard: View {
    @StateObject private var engine = SubscriptionEngine.shared

    var body: some View {
        if !engine.subscriptions.isEmpty {
            DS.Card {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DS.Colors.accent)

                        Text("Subscriptions")
                            .font(DS.Typography.section)
                            .foregroundStyle(DS.Colors.text)

                        Spacer()

                        NavigationLink(destination: SubscriptionsOverviewView()) {
                            Text("View All")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.Colors.accent)
                        }
                    }

                    // Monthly cost + count
                    HStack(alignment: .lastTextBaseline) {
                        Text("€\(DS.Format.currency(engine.monthlyTotal))")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Colors.text)

                        Text("/month")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(DS.Colors.subtext)

                        Spacer()

                        Text("\(engine.activeCount) active")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(DS.Colors.positive)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(DS.Colors.positive.opacity(0.1), in: Capsule())
                    }

                    // Upcoming renewals row (next 3)
                    let upcoming = engine.upcomingRenewals.prefix(3)
                    if !upcoming.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(upcoming)) { sub in
                                HStack(spacing: 8) {
                                    Image(systemName: sub.category.icon)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(sub.category.tint)
                                        .frame(width: 18)

                                    Text(sub.merchantName.capitalized)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(DS.Colors.text)
                                        .lineLimit(1)

                                    Spacer()

                                    Text("€\(DS.Format.currency(sub.expectedAmount))")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(DS.Colors.text)

                                    if let days = sub.daysUntilRenewal {
                                        Text(days == 0 ? "today" : days == 1 ? "tmrw" : "\(days)d")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(days <= 3 ? DS.Colors.warning : DS.Colors.subtext)
                                            .frame(width: 36, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }

                    // Insight warnings
                    let warnings = engine.insights.filter { $0 != .upcomingRenewal }
                    if !warnings.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(warnings.prefix(3)) { insight in
                                HStack(spacing: 3) {
                                    Image(systemName: insight.icon)
                                        .font(.system(size: 9))
                                    Text(insight.displayName)
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundStyle(insight.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(insight.color.opacity(0.1), in: Capsule())
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
