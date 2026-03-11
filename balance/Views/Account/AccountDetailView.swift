import SwiftUI
import Charts

// MARK: - Account Detail View

struct AccountDetailView: View {
    
    let account: Account
    
    @StateObject private var accountManager = AccountManager.shared
    @State private var balanceHistory: [AccountBalanceSnapshot] = []
    @State private var showEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                balanceCard
                
                if !balanceHistory.isEmpty {
                    balanceChartCard
                }
                
                detailsCard
                actionsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(DS.Colors.bg.ignoresSafeArea())
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditSheet = true }
                    .foregroundStyle(DS.Colors.accent)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditAccountView(mode: .edit(account))
        }
        .task { await loadHistory() }
    }
    
    // MARK: - Balance Card
    
    private var balanceCard: some View {
        DS.Card {
            VStack(spacing: 12) {
                Image(systemName: account.type.iconName)
                    .font(.title2)
                    .foregroundStyle(DS.Colors.accent)
                    .frame(width: 50, height: 50)
                    .background(DS.Colors.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                Text("Current Balance")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
                
                Text(formatCurrency(account.currentBalance))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Colors.text)
                
                // Asset / Liability badge
                Text(account.type.isAsset ? "Asset" : "Liability")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(account.type.isAsset ? DS.Colors.positive : DS.Colors.danger)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        (account.type.isAsset ? DS.Colors.positive : DS.Colors.danger).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                
                // Credit utilization
                if account.type == .creditCard, let limit = account.creditLimit, limit > 0 {
                    creditUtilizationBar(used: abs(account.currentBalance), limit: limit)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Credit Utilization
    
    private func creditUtilizationBar(used: Double, limit: Double) -> some View {
        let ratio = min(used / limit, 1.0)
        let color: Color = ratio > 0.75 ? DS.Colors.danger : (ratio > 0.5 ? DS.Colors.warning : DS.Colors.positive)
        
        return VStack(spacing: 6) {
            HStack {
                Text("Credit Used")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
                Spacer()
                Text("\(Int(ratio * 100))%")
                    .font(DS.Typography.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DS.Colors.grid)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * ratio, height: 5)
                }
            }
            .frame(height: 5)
            
            HStack {
                Text("\(formatCurrency(used)) used")
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Colors.subtext)
                Spacer()
                Text("\(formatCurrency(limit)) limit")
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Colors.subtext)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Balance Chart
    
    private var balanceChartCard: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Balance History")
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)
                
                if #available(iOS 16.0, *) {
                    Chart(balanceHistory) { snapshot in
                        LineMark(
                            x: .value("Date", snapshot.snapshotDate),
                            y: .value("Balance", snapshot.balance)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(DS.Colors.accent)
                        
                        AreaMark(
                            x: .value("Date", snapshot.snapshotDate),
                            y: .value("Balance", snapshot.balance)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DS.Colors.accent.opacity(0.2), DS.Colors.accent.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(formatCompact(amount))
                                        .font(.system(size: 10))
                                        .foregroundStyle(DS.Colors.subtext)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                        .font(.system(size: 10))
                                        .foregroundStyle(DS.Colors.subtext)
                                }
                            }
                        }
                    }
                    .frame(height: 170)
                }
            }
        }
    }
    
    // MARK: - Details Card
    
    private var detailsCard: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 0) {
                Text("Details")
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)
                    .padding(.bottom, 10)
                
                detailRow("Type", account.type.displayName)
                
                if let inst = account.institutionName, !inst.isEmpty {
                    Divider().padding(.vertical, 6)
                    detailRow("Institution", inst)
                }
                
                Divider().padding(.vertical, 6)
                detailRow("Currency", account.currency)
                
                if let rate = account.interestRate {
                    Divider().padding(.vertical, 6)
                    detailRow("Interest Rate", String(format: "%.2f%%", rate))
                }
                
                Divider().padding(.vertical, 6)
                detailRow("Created", account.createdAt.formatted(date: .abbreviated, time: .omitted))
                
                Divider().padding(.vertical, 6)
                detailRow("Updated", account.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }
    
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.subtext)
            Spacer()
            Text(value)
                .font(DS.Typography.body.weight(.medium))
                .foregroundStyle(DS.Colors.text)
        }
    }
    
    // MARK: - Actions
    
    private var actionsCard: some View {
        Button {
            Task { _ = await accountManager.archiveAccount(account) }
        } label: {
            HStack {
                Image(systemName: "archivebox")
                Text("Archive Account")
            }
            .font(DS.Typography.body.weight(.medium))
            .foregroundStyle(DS.Colors.warning)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(DS.Colors.warning.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
    
    // MARK: - Data
    
    private func loadHistory() async {
        do {
            let snapshots: [AccountBalanceSnapshot] = try await SupabaseManager.shared.client
                .from("account_balance_snapshots")
                .select()
                .eq("account_id", value: account.id.uuidString)
                .order("snapshot_date", ascending: true)
                .execute()
                .value
            balanceHistory = snapshots
        } catch {
            print("❌ Failed to load balance history: \(error)")
        }
    }
    
    // MARK: - Formatting
    
    private func formatCurrency(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = account.currency
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func formatCompact(_ value: Double) -> String {
        let abs = abs(value)
        if abs >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if abs >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return String(format: "$%.0f", value)
    }
}
