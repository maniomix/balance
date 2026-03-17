import SwiftUI

// ============================================================
// MARK: - Household Dashboard Card (Phase 5 Redesign)
// ============================================================
// Rich card showing: balance, shared budget, shared goals,
// pending settlements, and actionable alerts — so users can
// understand household status without opening the section.
// ============================================================

struct HouseholdDashboardCard: View {
    @Binding var store: Store
    @StateObject private var manager = HouseholdManager.shared
    @EnvironmentObject private var authManager: AuthManager
    @State private var showHousehold = false

    private var monthKey: String { Store.monthKey(store.selectedMonth) }
    private var currentUserId: String { authManager.currentUser?.uid ?? "" }

    var body: some View {
        if let h = manager.household {
            let snapshot = manager.dashboardSnapshot(
                monthKey: monthKey,
                currentUserId: currentUserId
            )

            Button {
                Haptics.light()
                showHousehold = true
            } label: {
                DS.Card {
                    VStack(alignment: .leading, spacing: 12) {
                        // Header row
                        headerRow(h, snapshot: snapshot)

                        // Balance + shared spending
                        balanceRow(h, snapshot: snapshot)

                        // Shared budget utilization (if set)
                        if let util = snapshot.budgetUtilization, snapshot.sharedBudget > 0 {
                            budgetBar(utilization: util, budget: snapshot.sharedBudget, spent: snapshot.sharedSpending, isOver: snapshot.isOverBudget)
                        }

                        // Shared goals (top goal progress)
                        if let goal = snapshot.topGoal {
                            sharedGoalRow(goal, totalCount: snapshot.activeSharedGoalCount)
                        }

                        // Actionable alerts
                        alertsRow(snapshot)
                    }
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showHousehold) {
                NavigationStack {
                    HouseholdOverviewView(store: $store)
                }
            }
        }
    }

    // MARK: - Header

    private func headerRow(_ h: Household, snapshot: HouseholdSnapshot) -> some View {
        HStack {
            Label(h.name, systemImage: "person.2.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DS.Colors.accent)

            Spacer()

            // Member avatars
            HStack(spacing: -6) {
                ForEach(h.members.prefix(3)) { member in
                    ZStack {
                        Circle()
                            .fill(member.role == .owner ? DS.Colors.accent : DS.Colors.positive)
                            .frame(width: 20, height: 20)

                        Text(String(member.displayName.prefix(1)).uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }

            if snapshot.pendingInviteCount > 0 {
                tagPill("\(snapshot.pendingInviteCount) invite", DS.Colors.accent)
            } else if !snapshot.hasPartner {
                tagPill("solo", DS.Colors.subtext)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(DS.Colors.subtext.opacity(0.3))
        }
    }

    // MARK: - Balance Row

    private func balanceRow(_ h: Household, snapshot: HouseholdSnapshot) -> some View {
        HStack(alignment: .firstTextBaseline) {
            // Net balance
            if let partner = h.partner, let owner = h.owner {
                let otherUser = currentUserId == owner.userId ? partner : owner
                let balance = manager.netBalance(fromUser: currentUserId, toUser: otherUser.userId)

                VStack(alignment: .leading, spacing: 2) {
                    if balance > 0 {
                        Text("You owe \(otherUser.displayName)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DS.Colors.subtext)
                        Text(DS.Format.money(balance))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Colors.danger)
                    } else if balance < 0 {
                        Text("\(otherUser.displayName) owes you")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DS.Colors.subtext)
                        Text(DS.Format.money(abs(balance)))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Colors.positive)
                    } else {
                        Text("All settled!")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Colors.positive)
                    }
                }
            } else {
                Label("Invite your partner", systemImage: "person.badge.plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.Colors.accent)
            }

            Spacer()

            // Shared spending this month
            if snapshot.sharedSpending > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(DS.Format.money(snapshot.sharedSpending))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Colors.text)
                    Text("shared this month")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DS.Colors.subtext)
                }
            }
        }
    }

    // MARK: - Budget Bar

    private func budgetBar(utilization: Double, budget: Int, spent: Int, isOver: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Shared Budget")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DS.Colors.subtext)
                Spacer()
                Text("\(DS.Format.money(spent)) / \(DS.Format.money(budget))")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(isOver ? DS.Colors.danger : DS.Colors.text)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(DS.Colors.surface2)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(isOver ? DS.Colors.danger : DS.Colors.accent)
                        .frame(width: geo.size.width * min(1.0, CGFloat(utilization)))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Shared Goal

    private func sharedGoalRow(_ goal: SharedGoal, totalCount: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: goal.icon)
                .font(.system(size: 10))
                .foregroundStyle(DS.Colors.accent)

            Text(goal.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DS.Colors.text)
                .lineLimit(1)

            Spacer()

            // Progress pill
            Text("\(goal.progressPercent)%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(goal.progress >= 0.75 ? DS.Colors.positive : DS.Colors.accent)

            // Mini progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(DS.Colors.surface2)
                    .frame(width: 40, height: 4)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(goal.progress >= 0.75 ? DS.Colors.positive : DS.Colors.accent)
                    .frame(width: 40 * min(1.0, CGFloat(goal.progress)), height: 4)
            }

            if totalCount > 1 {
                Text("+\(totalCount - 1)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Colors.subtext)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(DS.Colors.surface2, in: Capsule())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Alerts

    @ViewBuilder
    private func alertsRow(_ snapshot: HouseholdSnapshot) -> some View {
        let alerts = buildAlerts(snapshot)
        if !alerts.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(alerts.prefix(2), id: \.text) { alert in
                    HStack(spacing: 4) {
                        Image(systemName: alert.icon)
                            .font(.system(size: 10))
                        Text(alert.text)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(alert.color)
                }
            }
        }
    }

    private struct AlertItem: Hashable {
        let icon: String
        let text: String
        let color: Color
    }

    private func buildAlerts(_ snapshot: HouseholdSnapshot) -> [AlertItem] {
        var alerts: [AlertItem] = []

        if snapshot.isOverBudget {
            alerts.append(AlertItem(
                icon: "exclamationmark.triangle.fill",
                text: "Shared spending over budget",
                color: DS.Colors.danger
            ))
        }

        if snapshot.youOwe > 0 {
            alerts.append(AlertItem(
                icon: "arrow.uturn.right.circle.fill",
                text: "You owe \(DS.Format.money(snapshot.youOwe))",
                color: DS.Colors.warning
            ))
        } else if snapshot.owedToYou > 0 {
            alerts.append(AlertItem(
                icon: "arrow.uturn.left.circle.fill",
                text: "\(DS.Format.money(snapshot.owedToYou)) owed to you",
                color: DS.Colors.positive
            ))
        }

        if snapshot.unsettledCount > 3 {
            alerts.append(AlertItem(
                icon: "clock.fill",
                text: "\(snapshot.unsettledCount) expenses need settling",
                color: DS.Colors.warning
            ))
        }

        if !snapshot.hasPartner && snapshot.memberCount <= 1 {
            alerts.append(AlertItem(
                icon: "person.badge.plus",
                text: "Invite your partner to share finances",
                color: DS.Colors.accent
            ))
        }

        return alerts
    }

    // MARK: - Tag Pill

    private func tagPill(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1), in: Capsule())
    }
}
