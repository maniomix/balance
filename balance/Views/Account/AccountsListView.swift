import SwiftUI

// MARK: - Accounts List View

struct AccountsListView: View {
    
    @StateObject private var accountManager = AccountManager.shared
    @State private var showAddAccount = false
    @State private var accountToEdit: Account?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Net Worth Summary
                    netWorthCard
                    
                    // Assets
                    if !accountManager.assetAccounts.isEmpty {
                        accountSection(
                            title: "Assets",
                            accounts: accountManager.assetAccounts,
                            total: accountManager.totalAssets,
                            color: DS.Colors.positive
                        )
                    }
                    
                    // Liabilities
                    if !accountManager.liabilityAccounts.isEmpty {
                        accountSection(
                            title: "Liabilities",
                            accounts: accountManager.liabilityAccounts,
                            total: accountManager.totalLiabilities,
                            color: DS.Colors.danger
                        )
                    }
                    
                    // Empty State
                    if accountManager.activeAccounts.isEmpty && !accountManager.isLoading {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(DS.Colors.bg.ignoresSafeArea())
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAccount = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DS.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddEditAccountView(mode: .add)
            }
            .sheet(item: $accountToEdit) { account in
                AddEditAccountView(mode: .edit(account))
            }
            .task {
                await accountManager.fetchAccounts()
            }
            .refreshable {
                await accountManager.fetchAccounts()
            }
        }
    }
    
    // MARK: - Net Worth Card
    
    private var netWorthCard: some View {
        DS.Card {
            VStack(spacing: 12) {
                Text("Net Worth")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
                
                Text(formatCurrency(accountManager.netWorth))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Colors.text)
                
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Assets")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                        Text(formatCurrency(accountManager.totalAssets))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(DS.Colors.positive)
                    }
                    
                    Rectangle()
                        .fill(DS.Colors.grid)
                        .frame(width: 1, height: 30)
                    
                    VStack(spacing: 4) {
                        Text("Liabilities")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                        Text(formatCurrency(accountManager.totalLiabilities))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(DS.Colors.danger)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Account Section
    
    private func accountSection(
        title: String,
        accounts: [Account],
        total: Double,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)
                
                Spacer()
                
                Text(formatCurrency(total))
                    .font(DS.Typography.section)
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 4)
            
            ForEach(accounts) { account in
                NavigationLink(destination: AccountDetailView(account: account)) {
                    AccountRowView(account: account)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        accountToEdit = account
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        Task { _ = await accountManager.archiveAccount(account) }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "building.columns")
                .font(.system(size: 44))
                .foregroundStyle(DS.Colors.subtext.opacity(0.4))
            
            Text("No Accounts Yet")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.text)
            
            Text("Add your bank accounts, credit cards, and other financial accounts to track your net worth.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.subtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showAddAccount = true
            } label: {
                Label("Add Account", systemImage: "plus")
                    .font(DS.Typography.body.weight(.semibold))
            }
            .buttonStyle(DS.ColoredButton())
            .padding(.horizontal, 60)
        }
        .padding(.vertical, 40)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = "USD"
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Account Row

struct AccountRowView: View {
    let account: Account
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: account.type.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Colors.accent)
                .frame(width: 36, height: 36)
                .background(DS.Colors.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(DS.Typography.body.weight(.medium))
                    .foregroundStyle(DS.Colors.text)
                
                HStack(spacing: 4) {
                    Text(account.type.displayName)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                    
                    if let inst = account.institutionName, !inst.isEmpty {
                        Text("·")
                            .foregroundStyle(DS.Colors.subtext)
                        Text(inst)
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                    }
                }
            }
            
            Spacer()
            
            // Balance
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(account.currentBalance))
                    .font(DS.Typography.number)
                    .foregroundStyle(DS.Colors.text)
                
                if account.type == .creditCard, let avail = account.availableCredit {
                    Text("\(formatCurrency(avail)) available")
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Colors.subtext)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DS.Colors.subtext.opacity(0.4))
        }
        .padding(12)
        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = account.currency
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: value)) ?? "$0"
    }
}
