import Foundation
import Supabase
import Combine

// MARK: - Account Manager

@MainActor
class AccountManager: ObservableObject {
    
    static let shared = AccountManager()
    
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    private init() {}
    
    // MARK: - Current User ID
    
    private var currentUserId: UUID? {
        guard let uid = AuthManager.shared.currentUser?.uid else { return nil }
        return UUID(uuidString: uid)
    }
    
    // MARK: - Fetch Accounts
    
    func fetchAccounts() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [Account] = try await client
                .from("accounts")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("is_archived", value: false)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.accounts = response
            print("✅ Fetched \(response.count) accounts")
        } catch {
            self.errorMessage = "Failed to load accounts: \(error.localizedDescription)"
            print("❌ Fetch accounts failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Fetch all accounts including archived (for net worth history)
    func fetchAllAccounts() async -> [Account] {
        guard let userId = currentUserId else { return [] }
        do {
            let response: [Account] = try await client
                .from("accounts")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            return response
        } catch {
            return []
        }
    }
    
    // MARK: - Create Account
    
    func createAccount(_ account: Account) async -> Bool {
        do {
            try await client
                .from("accounts")
                .insert(account)
                .execute()
            
            print("✅ Account created: \(account.name)")
            
            // Take initial balance snapshot
            await takeSnapshot(for: account)
            await fetchAccounts()
            return true
        } catch {
            self.errorMessage = "Failed to create account: \(error.localizedDescription)"
            print("❌ Create account failed: \(error)")
            return false
        }
    }
    
    // MARK: - Update Account
    
    func updateAccount(_ account: Account) async -> Bool {
        var updated = account
        updated.updatedAt = Date()
        
        do {
            try await client
                .from("accounts")
                .update(updated)
                .eq("id", value: updated.id.uuidString)
                .execute()
            
            print("✅ Account updated: \(account.name)")
            await fetchAccounts()
            return true
        } catch {
            self.errorMessage = "Failed to update account: \(error.localizedDescription)"
            print("❌ Update account failed: \(error)")
            return false
        }
    }
    
    // MARK: - Archive Account (Soft Delete)
    
    func archiveAccount(_ account: Account) async -> Bool {
        var archived = account
        archived.isArchived = true
        archived.updatedAt = Date()
        return await updateAccount(archived)
    }
    
    // MARK: - Delete Account (Hard Delete)
    
    func deleteAccount(_ account: Account) async -> Bool {
        do {
            // Delete associated snapshots first
            try await client
                .from("account_balance_snapshots")
                .delete()
                .eq("account_id", value: account.id.uuidString)
                .execute()
            
            // Delete the account
            try await client
                .from("accounts")
                .delete()
                .eq("id", value: account.id.uuidString)
                .execute()
            
            print("✅ Account deleted: \(account.name)")
            await fetchAccounts()
            return true
        } catch {
            self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
            print("❌ Delete account failed: \(error)")
            return false
        }
    }
    
    // MARK: - Balance Updates
    
    /// Update account balance after a transaction is added
    func adjustBalance(accountId: UUID, amount: Double, isExpense: Bool) async {
        guard var account = accounts.first(where: { $0.id == accountId }) else { return }
        
        if account.type.isAsset {
            // Assets: expenses decrease, income increases
            account.currentBalance += isExpense ? -amount : amount
        } else {
            // Liabilities: expenses increase (more owed), income decreases
            account.currentBalance += isExpense ? amount : -amount
        }
        
        account.updatedAt = Date()
        _ = await updateAccount(account)
    }
    
    /// Reverse a balance adjustment (e.g., when deleting a transaction)
    func reverseBalanceAdjustment(accountId: UUID, amount: Double, isExpense: Bool) async {
        await adjustBalance(accountId: accountId, amount: amount, isExpense: !isExpense)
    }
    
    // MARK: - Balance Snapshots
    
    func takeSnapshot(for account: Account) async {
        let snapshot = AccountBalanceSnapshot(
            accountId: account.id,
            balance: account.currentBalance
        )
        do {
            try await client
                .from("account_balance_snapshots")
                .insert(snapshot)
                .execute()
        } catch {
            print("⚠️ Failed to take snapshot: \(error.localizedDescription)")
        }
    }
    
    /// Take snapshots for all active accounts (call on app open)
    func takeDailySnapshots() async {
        for account in accounts {
            await takeSnapshot(for: account)
        }
        print("✅ Daily snapshots taken for \(accounts.count) accounts")
    }
    
    // MARK: - Computed Properties
    
    var activeAccounts: [Account] {
        accounts.filter { !$0.isArchived }
    }
    
    var assetAccounts: [Account] {
        activeAccounts.filter { $0.type.isAsset }
    }
    
    var liabilityAccounts: [Account] {
        activeAccounts.filter { $0.type.isLiability }
    }
    
    var totalAssets: Double {
        assetAccounts.reduce(0) { $0 + $1.currentBalance }
    }
    
    var totalLiabilities: Double {
        liabilityAccounts.reduce(0) { $0 + abs($1.currentBalance) }
    }
    
    var netWorth: Double {
        totalAssets - totalLiabilities
    }
}
