import SwiftUI

// ============================================================
// MARK: - Household Dashboard Card (Redesigned)
// ============================================================
// Clean horizontal card: partner balance + shared spending.
// Only visible when user is in a household.
// ============================================================

struct HouseholdDashboardCard: View {
    @Binding var store: Store
    @StateObject private var manager = HouseholdManager.shared
    @EnvironmentObject private var authManager: AuthManager
    @State private var showHousehold = false

    var body: some View {
        if let h = manager.household {
            Button {
                Haptics.light()
                showHousehold = true
            } label: {
                DS.Card {
                    HStack(spacing: 14) {
                        // Icon
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(DS.Colors.accent.opacity(0.12))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(DS.Colors.accent)
                            )

                        // Content
                        VStack(alignment: .leading, spacing: 4) {
                            Text(h.name)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.Colors.text)

                            if let partner = h.partner, let owner = h.owner {
                                let currentUserId = authManager.currentUser?.uid ?? ""
                                let otherUser = currentUserId == owner.userId ? partner : owner
                                let balance = manager.netBalance(fromUser: currentUserId, toUser: otherUser.userId)

                                balanceLabel(balance: balance, partnerName: otherUser.displayName)
                            } else {
                                Label("Invite your partner", systemImage: "person.badge.plus")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(DS.Colors.accent)
                            }
                        }

                        Spacer()

                        // Right side: stats
                        VStack(alignment: .trailing, spacing: 4) {
                            let monthKey = Store.monthKey(store.selectedMonth)
                            let shared = manager.sharedSpending(monthKey: monthKey)
                            if shared > 0 {
                                Text(DS.Format.money(shared))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(DS.Colors.text)
                                Text("shared")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(DS.Colors.subtext)
                            }

                            let unsettled = manager.unsettledExpenses.count
                            if unsettled > 0 {
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(DS.Colors.warning)
                                        .frame(width: 5, height: 5)
                                    Text("\(unsettled) open")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(DS.Colors.warning)
                                }
                            }
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(DS.Colors.subtext.opacity(0.3))
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

    @ViewBuilder
    private func balanceLabel(balance: Int, partnerName: String) -> some View {
        if balance > 0 {
            HStack(spacing: 4) {
                Text("You owe")
                    .foregroundStyle(DS.Colors.subtext)
                Text(DS.Format.money(balance))
                    .foregroundStyle(DS.Colors.danger)
            }
            .font(.system(size: 11, weight: .medium))
        } else if balance < 0 {
            HStack(spacing: 4) {
                Text("\(partnerName) owes")
                    .foregroundStyle(DS.Colors.subtext)
                Text(DS.Format.money(abs(balance)))
                    .foregroundStyle(DS.Colors.positive)
            }
            .font(.system(size: 11, weight: .medium))
        } else {
            Text("All settled!")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DS.Colors.positive)
        }
    }
}
