import SwiftUI

// ============================================================
// MARK: - Subscriptions Dashboard Card (Redesigned)
// ============================================================
// Clean horizontal layout: monthly total + next 2 renewals.
// ============================================================

struct SubscriptionsDashboardCard: View {
    @StateObject private var engine = SubscriptionEngine.shared

    var body: some View {
        if !engine.subscriptions.isEmpty {
            NavigationLink(destination: SubscriptionsOverviewView()) {
                DS.Card {
                    VStack(alignment: .leading, spacing: 12) {
                        // Header
                        HStack {
                            Label("Subscriptions", systemImage: "creditcard.and.123")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DS.Colors.accent)

                            Spacer()

                            Text("\(engine.activeCount) active")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DS.Colors.positive)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(DS.Colors.positive.opacity(0.1), in: Capsule())

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(DS.Colors.subtext.opacity(0.3))
                        }

                        // Monthly total
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(DS.Format.money(engine.monthlyTotal))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(DS.Colors.text)
                            Text("/month")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(DS.Colors.subtext)

                            Spacer()

                            Text(DS.Format.money(engine.yearlyTotal) + "/year")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(DS.Colors.subtext)
                        }

                        // Next renewals (up to 2)
                        let upcoming = Array(engine.upcomingRenewals.prefix(2))
                        if !upcoming.isEmpty {
                            HStack(spacing: 8) {
                                ForEach(upcoming) { sub in
                                    HStack(spacing: 6) {
                                        Image(systemName: sub.category.icon)
                                            .font(.system(size: 10))
                                            .foregroundStyle(sub.category.tint)

                                        Text(sub.merchantName.capitalized)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(DS.Colors.text)
                                            .lineLimit(1)

                                        Text(DS.Format.money(sub.expectedAmount))
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(DS.Colors.text)

                                        if let days = sub.daysUntilRenewal {
                                            Text(days == 0 ? "today" : days == 1 ? "tmrw" : "\(days)d")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(days <= 3 ? DS.Colors.warning : DS.Colors.subtext)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                                    if sub.id != upcoming.last?.id {
                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                        }

                        // Actionable insights (not just labels — real alerts)
                        let snapshot = engine.dashboardSnapshot
                        VStack(alignment: .leading, spacing: 6) {
                            // Price increases
                            if snapshot.priceIncreaseCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 10))
                                    Text("\(snapshot.priceIncreaseCount) price increase\(snapshot.priceIncreaseCount == 1 ? "" : "s")")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundStyle(DS.Colors.danger)
                            }

                            // Unused subscriptions with savings
                            if snapshot.unusedCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 10))
                                    Text("\(snapshot.unusedCount) maybe unused — save \(DS.Format.money(snapshot.potentialSavings))/mo")
                                        .font(.system(size: 10, weight: .semibold))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(Color(hexValue: 0x9B59B6))
                            }

                            // Missed charges
                            if snapshot.missedChargeCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                    Text("\(snapshot.missedChargeCount) missed charge\(snapshot.missedChargeCount == 1 ? "" : "s")")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundStyle(DS.Colors.warning)
                            }

                            // Other insight badges (duplicate risk, newly detected)
                            let badges = engine.insights.filter {
                                $0 != .upcomingRenewal && $0 != .priceIncreased && $0 != .maybeUnused && $0 != .missedCharge
                            }
                            if !badges.isEmpty {
                                HStack(spacing: 6) {
                                    ForEach(badges.prefix(2)) { insight in
                                        Label(insight.displayName, systemImage: insight.icon)
                                            .font(.system(size: 9, weight: .bold))
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
            .buttonStyle(.plain)
        }
    }
}
