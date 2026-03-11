import SwiftUI

// MARK: - Net Worth Dashboard Card

/// Drop this into DashboardView to show net worth at a glance.
/// Tapping it navigates to the full AccountsListView.
struct NetWorthDashboardCard: View {
    
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var netWorthManager = NetWorthManager.shared
    
    var body: some View {
        NavigationLink(destination: AccountsListView()) {
            DS.Card {
                VStack(spacing: 12) {
                    // Header row
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(DS.Colors.accent)
                            Text("Net Worth")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                        }
                        
                        Spacer()
                        
                        // Monthly change badge
                        if netWorthManager.summary.changeFromLastMonth != 0 {
                            changeBadge
                        }
                    }
                    
                    // Amount
                    HStack(alignment: .firstTextBaseline) {
                        Text(formatCurrency(netWorthManager.summary.netWorth))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(DS.Colors.subtext.opacity(0.4))
                    }
                    
                    // Assets vs Liabilities bar
                    HStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Circle().fill(DS.Colors.positive).frame(width: 6, height: 6)
                            Text(formatCompact(accountManager.totalAssets))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(DS.Colors.positive)
                        }
                        
                        Spacer()
                        
                        assetLiabilityBar
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text(formatCompact(accountManager.totalLiabilities))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(DS.Colors.danger)
                            Circle().fill(DS.Colors.danger).frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .task {
            await accountManager.fetchAccounts()
            await netWorthManager.computeSummary()
        }
    }
    
    // MARK: - Change Badge
    
    private var changeBadge: some View {
        let change = netWorthManager.summary.changeFromLastMonth
        let isPositive = change >= 0
        let color: Color = isPositive ? DS.Colors.positive : DS.Colors.danger
        let icon = isPositive ? "arrow.up.right" : "arrow.down.right"
        
        return HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(String(format: "%.1f%%", abs(netWorthManager.summary.changePercentage)))
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
    
    // MARK: - Asset/Liability Bar
    
    private var assetLiabilityBar: some View {
        let total = accountManager.totalAssets + accountManager.totalLiabilities
        let ratio: CGFloat = total > 0 ? CGFloat(accountManager.totalAssets / total) : 0.5
        
        return GeometryReader { geo in
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(DS.Colors.positive)
                    .frame(width: geo.size.width * ratio)
                RoundedRectangle(cornerRadius: 2)
                    .fill(DS.Colors.danger)
                    .frame(width: geo.size.width * (1 - ratio))
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 6)
    }
    
    // MARK: - Formatting
    
    private func formatCurrency(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = "USD"
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return String(format: "$%.0f", value)
    }
}
