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

                        // Insight warnings
                        let warnings = engine.insights.filter { $0 != .upcomingRenewal }
                        if !warnings.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(warnings.prefix(2)) { insight in
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
            .buttonStyle(.plain)
        }
    }
}
