import Foundation
import Supabase
import SwiftUI
import Combine

// MARK: - Supabase Manager
@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    var client: SupabaseClient! // Made public for AuthManager
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var lastSyncTime: Date?
    @Published var lastSyncDate: Date? // For compatibility with views
    @Published var isSyncing = false
    @Published var syncError: String?
    
    init() {
        setupClient()
    }
    
    private func setupClient() {
        // Load from Supabase.plist
        guard let path = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let url = config["SUPABASE_URL"] as? String,
              let anonKey = config["SUPABASE_ANON_KEY"] as? String else {
            print("❌ Missing Supabase.plist")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: URL(string: url)!,
            supabaseKey: anonKey
        )
        
        print("✅ Supabase client initialized")
        
        // Listen for auth changes
        Task {
            for await state in await client.auth.authStateChanges {
                await MainActor.run {
                    self.currentUser = state.session?.user
                    self.isAuthenticated = state.session != nil
                    print("🔐 Auth state changed: \(self.isAuthenticated)")
                }
            }
        }
    }
    
    // MARK: - Auth Methods
    
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        print("📝 Signing up: \(email)")
        
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            print("✅ Auth sign up successful")
            print("   User ID: \(response.user.id.uuidString)")
            
            // Create user profile
            let userId = response.user.id.uuidString
            
            let userData: [String: String] = [
                "id": userId,
                "email": email,
                "display_name": displayName ?? "User"
            ]
            
            print("📊 Inserting user profile: \(userData)")
            
            try await client.database
                .from("users")
                .insert(userData)
                .execute()
            
            print("✅ User profile created")
            print("✅ Sign up completed successfully!")
            
        } catch {
            print("❌ Sign up error: \(error)")
            print("   Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("🔑 Signing in: \(email)")
        try await client.auth.signIn(email: email, password: password)
        print("✅ Sign in successful")
    }
    
    func signOut() throws {
        print("👋 Signing out")
        Task {
            try await client.auth.signOut()
        }
    }
    
    func resetPassword(email: String) async throws {
        print("🔄 Resetting password for: \(email)")
        try await client.auth.resetPasswordForEmail(email)
        print("✅ Password reset email sent")
    }
    
    func changePassword(newPassword: String) async throws {
        print("🔒 Changing password")
        try await client.auth.update(user: UserAttributes(password: newPassword))
        print("✅ Password changed")
    }
    
    // MARK: - Store Sync (Complete Store)
    
    func syncStore(_ localStore: Store) async throws -> Store {
        guard let userId = currentUser?.id.uuidString else {
            throw NSError(domain: "Supabase", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        print("🔄 Syncing store...")
        
        // Load all data
        let transactions = try await loadTransactions(userId: userId)
        let budgets = try await loadBudgets(userId: userId)
        let categoryBudgets = try await loadCategoryBudgets(userId: userId)
        let customCategories = try await loadCustomCategories(userId: userId)
        let recurringTransactions = try await loadRecurringTransactions(userId: userId)
        
        // Create new store with synced data
        var syncedStore = localStore
        syncedStore.transactions = transactions
        syncedStore.budgetsByMonth = budgets
        syncedStore.categoryBudgetsByMonth = categoryBudgets
        syncedStore.customCategoriesWithIcons = customCategories
        syncedStore.recurringTransactions = recurringTransactions
        
        // ✅ Sync customCategoryNames from server (not merge with local)
        syncedStore.customCategoryNames = customCategories.map { $0.name }.sorted { $0.lowercased() < $1.lowercased() }
        
        lastSyncTime = Date()
        lastSyncDate = Date()
        syncError = nil
        
        print("✅ Store synced: \(transactions.count) transactions, \(recurringTransactions.count) recurring, \(customCategories.count) custom categories")
        return syncedStore
    }
    
    func saveStore(_ store: Store) async throws {
        guard let userId = currentUser?.id.uuidString else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        print("💾 Saving store...")
        
        // 1. Hard delete removed transactions from Supabase
        for deletedId in store.deletedTransactionIds {
            if let uuid = UUID(uuidString: deletedId) {
                do {
                    try await deleteTransaction(uuid)
                    print("🗑️ Deleted transaction: \(deletedId)")
                } catch {
                    print("❌ Failed to delete transaction \(deletedId): \(error)")
                }
            }
        }
        
        // 2. Save all active transactions
        for transaction in store.transactions {
            try await saveTransaction(transaction, userId: userId)
        }
        
        // 3. Save budgets + delete removed months from server
        let localBudgetMonths = Set(store.budgetsByMonth.keys)
        
        // Load server budget months
        struct BudgetMonthDTO: Codable { let month: String }
        let serverBudgets: [BudgetMonthDTO] = try await client.database
            .from("budgets")
            .select("month")
            .eq("user_id", value: userId.lowercased())
            .execute()
            .value
        
        // Delete budgets that exist on server but not locally
        for sb in serverBudgets {
            if !localBudgetMonths.contains(sb.month) {
                print("🗑️ Deleting budget for month \(sb.month) from server")
                try await client.database
                    .from("budgets")
                    .delete()
                    .eq("user_id", value: userId.lowercased())
                    .eq("month", value: sb.month)
                    .execute()
                
                // Also delete all category budgets for that month
                print("🗑️ Deleting category budgets for month \(sb.month) from server")
                try await client.database
                    .from("category_budgets")
                    .delete()
                    .eq("user_id", value: userId.lowercased())
                    .eq("month", value: sb.month)
                    .execute()
            }
        }
        
        for (monthKey, amount) in store.budgetsByMonth {
            if let month = monthKeyToDate(monthKey) {
                try await saveBudget(userId: userId, month: month, amount: amount)
            }
        }
        
        // 4. Save category budgets + clean removed ones
        let localCatBudgetMonths = Set(store.categoryBudgetsByMonth.keys)
        
        for (monthKey, categoriesDict) in store.categoryBudgetsByMonth {
            if let month = monthKeyToDate(monthKey) {
                for (categoryKey, amount) in categoriesDict {
                    try await saveCategoryBudget(userId: userId, month: month, category: categoryKey, amount: amount)
                }
            }
        }
        
        // Delete category budgets for months not in local
        struct CatBudgetMonthDTO: Codable { let month: String }
        let serverCatBudgets: [CatBudgetMonthDTO] = try await client.database
            .from("category_budgets")
            .select("month")
            .eq("user_id", value: userId.lowercased())
            .execute()
            .value
        
        let serverCatMonths = Set(serverCatBudgets.map { $0.month })
        for month in serverCatMonths {
            if !localCatBudgetMonths.contains(month) {
                try await client.database
                    .from("category_budgets")
                    .delete()
                    .eq("user_id", value: userId.lowercased())
                    .eq("month", value: month)
                    .execute()
            }
        }
        
        // 5. Save custom categories
        try await saveCustomCategories(store.customCategoriesWithIcons, userId: userId)
        
        // 6. Save recurring transactions
        try await saveRecurringTransactions(store.recurringTransactions, userId: userId)
        
        lastSyncTime = Date()
        print("✅ Store saved")
    }
    
    // MARK: - Transactions
    
    func saveTransaction(_ transaction: Transaction, userId: String) async throws {
        let dateFormatter = ISO8601DateFormatter()
        
        let data: [String: String] = [
            "id": transaction.id.uuidString,
            "user_id": userId.lowercased(),
            "amount": String(transaction.amount),
            "category": transaction.category.storageKey,
            "type": transaction.type == .income ? "income" : "expense",
            "note": transaction.note,
            "date": dateFormatter.string(from: transaction.date)
        ]
        
        try await client.database
            .from("transactions")
            .upsert(data)
            .execute()
    }
    
    func loadTransactions(userId: String) async throws -> [Transaction] {
        // ⚠️ Important: Supabase stores UUIDs in lowercase, but Swift returns uppercase
        let userIdLowercase = userId.lowercased()
        
        struct TransactionDTO: Codable {
            let id: String
            let amount: Int
            let category: String
            let type: String
            let note: String?
            let date: String
        }
        
        print("🔍 Loading transactions for user: \(userIdLowercase)")
        
        let response: [TransactionDTO] = try await client.database
            .from("transactions")
            .select()
            .eq("user_id", value: userIdLowercase)
            .order("date", ascending: false)
            .execute()
            .value
        
        print("📦 Received \(response.count) transactions from Supabase")
        
        var parsedCount = 0
        var failedCount = 0
        
        let transactions = response.compactMap { dto -> Transaction? in
            // Debug: print first transaction details
            if parsedCount == 0 && failedCount == 0 {
                print("🔍 First transaction data:")
                print("   - id: \(dto.id)")
                print("   - date: \(dto.date)")
                print("   - amount: \(dto.amount)")
                print("   - category: \(dto.category)")
            }
            
            guard let uuid = UUID(uuidString: dto.id) else {
                failedCount += 1
                print("❌ Failed to parse UUID: \(dto.id)")
                return nil
            }
            
            // Parse date - handle both "YYYY-MM-DD" and ISO8601 formats
            let date: Date
            if let isoDate = ISO8601DateFormatter().date(from: dto.date) {
                date = isoDate
            } else {
                // Try simple date format "YYYY-MM-DD"
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let simpleDate = formatter.date(from: dto.date) {
                    date = simpleDate
                } else {
                    failedCount += 1
                    print("❌ Failed to parse date: \(dto.date)")
                    return nil
                }
            }
            
            // Parse category from storage key
            let category: Category
            if dto.category.hasPrefix("custom:") {
                let customName = String(dto.category.dropFirst(7))
                category = .custom(customName)
            } else {
                switch dto.category {
                case "groceries": category = .groceries
                case "rent": category = .rent
                case "bills": category = .bills
                case "transport": category = .transport
                case "health": category = .health
                case "education": category = .education
                case "dining": category = .dining
                case "shopping": category = .shopping
                default: category = .other
                }
            }
            
            parsedCount += 1
            
            return Transaction(
                id: uuid,
                amount: dto.amount,
                date: date,
                category: category,
                note: dto.note ?? "",
                type: dto.type == "income" ? .income : .expense
            )
        }
        
        print("✅ Successfully parsed: \(parsedCount) transactions")
        print("❌ Failed to parse: \(failedCount) transactions")
        
        return transactions
    }
    
    func deleteTransaction(_ transactionId: UUID) async throws {
        try await client.database
            .from("transactions")
            .delete()
            .eq("id", value: transactionId.uuidString.lowercased())
            .execute()
    }
    
    // MARK: - Budgets
    
    func saveBudget(userId: String, month: Date, amount: Int) async throws {
        let monthStr = dateToMonthKey(month)
        
        let data: [String: String] = [
            "user_id": userId.lowercased(),
            "month": monthStr,
            "total_amount": String(amount)
        ]
        
        try await client.database
            .from("budgets")
            .upsert(data, onConflict: "user_id,month")
            .execute()
    }
    
    func loadBudgets(userId: String) async throws -> [String: Int] {
        struct BudgetDTO: Codable {
            let month: String
            let total_amount: Int
        }
        
        let response: [BudgetDTO] = try await client.database
            .from("budgets")
            .select()
            .eq("user_id", value: userId.lowercased())
            .execute()
            .value
        
        var budgets: [String: Int] = [:]
        for budget in response {
            budgets[budget.month] = budget.total_amount
        }
        return budgets
    }
    
    // MARK: - Category Budgets
    
    func saveCategoryBudget(userId: String, month: Date, category: String, amount: Int) async throws {
        let monthStr = dateToMonthKey(month)
        
        let data: [String: String] = [
            "user_id": userId.lowercased(),
            "month": monthStr,
            "category": category,
            "amount": String(amount)
        ]
        
        try await client.database
            .from("category_budgets")
            .upsert(data, onConflict: "user_id,month,category")
            .execute()
    }
    
    func loadCategoryBudgets(userId: String) async throws -> [String: [String: Int]] {
        struct CategoryBudgetDTO: Codable {
            let month: String
            let category: String
            let amount: Int
        }
        
        let response: [CategoryBudgetDTO] = try await client.database
            .from("category_budgets")
            .select()
            .eq("user_id", value: userId.lowercased())
            .execute()
            .value
        
        var budgets: [String: [String: Int]] = [:]
        for budget in response {
            if budgets[budget.month] == nil {
                budgets[budget.month] = [:]
            }
            budgets[budget.month]?[budget.category] = budget.amount
        }
        return budgets
    }
    
    // MARK: - Real-time Sync
    
    private var realtimeChannel: RealtimeChannelV2?
    
    func startRealtimeSync(userId: String, onUpdate: @escaping () -> Void) {
        print("🎧 Real-time sync disabled for now")
        // TODO: Implement real-time sync properly
    }
    
    func stopRealtimeSync() {
        print("🛑 Stopping real-time sync")
        realtimeChannel = nil
    }
    
    // MARK: - Analytics
    
    func trackEvent(name: String, properties: [String: Any]? = nil) async {
        guard let userId = currentUser?.id.uuidString else { return }
        
        do {
            // Convert properties to JSON string
            var propsJson = "{}"
            if let properties = properties {
                let stringProps = properties.mapValues { "\($0)" }
                if let jsonData = try? JSONSerialization.data(withJSONObject: stringProps),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    propsJson = jsonString
                }
            }
            
            let data: [String: String] = [
                "user_id": userId.lowercased(),
                "event_name": name,
                "event_properties": propsJson
            ]
            
            try await client.database
                .from("events")
                .insert(data)
                .execute()
        } catch {
            print("⚠️ Failed to track event: \(error)")
        }
    }
    
    func updateLastActive() async throws {
        guard let userId = currentUser?.id.uuidString else { return }
        
        try await client.database
            .from("users")
            .update(["last_active_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Delete Month Data
    
    /// حذف کامل داده‌های یک ماه از Supabase
    /// شامل: transactions, budgets, category_budgets
    func deleteMonthData(userId: String, monthKey: String) async throws {
        let userIdLower = userId.lowercased()
        
        print("🗑️ Deleting month \(monthKey) from Supabase...")
        
        // 1. حذف تراکنش‌های این ماه
        // date ها به فرمت ISO8601 هستن: "2026-03-15T..." پس با like فیلتر میکنیم
        // هم فرمت ISO8601 و هم YYYY-MM-DD رو ساپورت میکنه
        try await client.database
            .from("transactions")
            .delete()
            .eq("user_id", value: userIdLower)
            .like("date", pattern: "\(monthKey)%")
            .execute()
        
        print("  ✅ Deleted transactions for \(monthKey)")
        
        // 2. حذف بودجه کل این ماه
        try await client.database
            .from("budgets")
            .delete()
            .eq("user_id", value: userIdLower)
            .eq("month", value: monthKey)
            .execute()
        
        print("  ✅ Deleted budget for \(monthKey)")
        
        // 3. حذف category budgets این ماه
        try await client.database
            .from("category_budgets")
            .delete()
            .eq("user_id", value: userIdLower)
            .eq("month", value: monthKey)
            .execute()
        
        print("  ✅ Deleted category budgets for \(monthKey)")
        
        print("🗑️ Month \(monthKey) fully deleted from Supabase")
    }
    
    // MARK: - Helpers
    
    private func dateToMonthKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
    
    private func monthKeyToDate(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: key)
    }
}

// MARK: - Recurring Transactions
extension SupabaseManager {
    
    func saveRecurringTransactions(_ recurring: [RecurringTransaction], userId: String) async throws {
        let userIdLower = userId.lowercased()
        let dateFormatter = ISO8601DateFormatter()
        
        print("💾 Saving \(recurring.count) recurring transactions...")
        
        // Get existing IDs from server
        struct IdDTO: Codable { let id: String }
        let existing: [IdDTO] = try await client.database
            .from("recurring_transactions")
            .select("id")
            .eq("user_id", value: userIdLower)
            .execute()
            .value
        
        let existingIds = Set(existing.map { $0.id.lowercased() })
        let localIds = Set(recurring.map { $0.id.uuidString.lowercased() })
        
        // Hard delete ones that exist on server but not locally
        let deletedIds = existingIds.subtracting(localIds)
        for deletedId in deletedIds {
            try await client.database
                .from("recurring_transactions")
                .delete()
                .eq("id", value: deletedId)
                .execute()
        }
        
        // Upsert all local recurring
        for item in recurring {
            var data: [String: String] = [
                "id": item.id.uuidString.lowercased(),
                "user_id": userIdLower,
                "name": item.name,
                "amount": String(item.amount),
                "category": item.category.storageKey,
                "frequency": item.frequency.rawValue,
                "start_date": dateFormatter.string(from: item.startDate),
                "is_active": item.isActive ? "true" : "false",
                "payment_method": item.paymentMethod.rawValue,
                "note": item.note
            ]
            
            if let endDate = item.endDate {
                data["end_date"] = dateFormatter.string(from: endDate)
            }
            
            if let lastProcessed = item.lastProcessedDate {
                data["last_processed_date"] = dateFormatter.string(from: lastProcessed)
            }
            
            try await client.database
                .from("recurring_transactions")
                .upsert(data)
                .execute()
        }
        
        print("✅ Recurring transactions saved (\(recurring.count) upserted, \(deletedIds.count) deleted)")
    }
    
    func loadRecurringTransactions(userId: String) async throws -> [RecurringTransaction] {
        let userIdLower = userId.lowercased()
        
        struct RecurringDTO: Codable {
            let id: String
            let name: String
            let amount: Int
            let category: String
            let frequency: String
            let start_date: String
            let end_date: String?
            let is_active: Bool
            let last_processed_date: String?
            let payment_method: String?
            let note: String?
        }
        
        print("📥 Loading recurring transactions...")
        
        let response: [RecurringDTO] = try await client.database
            .from("recurring_transactions")
            .select()
            .eq("user_id", value: userIdLower)
            .execute()
            .value
        
        let isoFormatter = ISO8601DateFormatter()
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        simpleFormatter.locale = Locale(identifier: "en_US_POSIX")
        simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        func parseDate(_ str: String) -> Date? {
            isoFormatter.date(from: str) ?? simpleFormatter.date(from: str)
        }
        
        func parseCategory(_ key: String) -> Category {
            if key.hasPrefix("custom:") {
                return .custom(String(key.dropFirst(7)))
            }
            switch key {
            case "groceries": return .groceries
            case "rent": return .rent
            case "bills": return .bills
            case "transport": return .transport
            case "health": return .health
            case "education": return .education
            case "dining": return .dining
            case "shopping": return .shopping
            default: return .other
            }
        }
        
        func parseFrequency(_ raw: String) -> RecurringFrequency {
            switch raw {
            case "daily": return .daily
            case "weekly": return .weekly
            case "monthly": return .monthly
            case "yearly": return .yearly
            default: return .monthly
            }
        }
        
        func parsePaymentMethod(_ raw: String?) -> PaymentMethod {
            guard let raw = raw else { return .card }
            return PaymentMethod(rawValue: raw) ?? .card
        }
        
        let results = response.compactMap { dto -> RecurringTransaction? in
            guard let uuid = UUID(uuidString: dto.id),
                  let startDate = parseDate(dto.start_date) else {
                print("❌ Failed to parse recurring: \(dto.id)")
                return nil
            }
            
            return RecurringTransaction(
                id: uuid,
                name: dto.name,
                amount: dto.amount,
                category: parseCategory(dto.category),
                frequency: parseFrequency(dto.frequency),
                startDate: startDate,
                endDate: dto.end_date.flatMap { parseDate($0) },
                isActive: dto.is_active,
                lastProcessedDate: dto.last_processed_date.flatMap { parseDate($0) },
                paymentMethod: parsePaymentMethod(dto.payment_method),
                note: dto.note ?? ""
            )
        }
        
        print("✅ Loaded \(results.count) recurring transactions")
        return results
    }
}

// MARK: - Custom Categories
extension SupabaseManager {
    
    /// Save custom categories to Supabase
    func saveCustomCategories(_ categories: [CustomCategoryModel], userId: String) async throws {
        print("💾 Saving \(categories.count) custom categories...")
        print("🔍 User ID: \(userId)")
        print("🔍 Categories to save: \(categories)")
        
        let jsonData = try JSONEncoder().encode(categories)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
        
        print("🔍 JSON string to save: \(jsonString)")
        
        try await client
            .from("users")
            .update(["custom_categories": jsonString])
            .eq("id", value: userId)
            .execute()
        
        print("✅ Custom categories saved to Supabase")
        
        // Verify it was saved
        print("🔍 Verifying save...")
        let categories = try await loadCustomCategories(userId: userId)
        print("🔍 Verified: \(categories.count) categories in database")
    }
    
    /// Load custom categories from Supabase
    func loadCustomCategories(userId: String) async throws -> [CustomCategoryModel] {
        print("📥 Loading custom categories...")
        print("🔍 User ID: \(userId)")
        
        // Try decoding as array first (if JSONB native)
        struct UserDataArray: Decodable {
            let custom_categories: [CustomCategoryModel]?
        }
        
        // Fallback: decode as string (if stored as JSON string)
        struct UserDataString: Decodable {
            let custom_categories: String?
        }
        
        do {
            // Try array format first
            let response: [UserDataArray] = try await client
                .from("users")
                .select("custom_categories")
                .eq("id", value: userId)
                .execute()
                .value
            
            print("🔍 Response count: \(response.count)")
            print("🔍 Raw response: \(response)")
            
            if let user = response.first,
               let categories = user.custom_categories {
                print("✅ Loaded \(categories.count) custom categories (array format)")
                print("🔍 Categories: \(categories)")
                return categories
            }
        } catch {
            print("⚠️ Not array format, error: \(error)")
            print("⚠️ Trying string format...")
            
            // Try string format
            do {
                let response: [UserDataString] = try await client
                    .from("users")
                    .select("custom_categories")
                    .eq("id", value: userId)
                    .execute()
                    .value
                
                print("🔍 String response count: \(response.count)")
                
                if let user = response.first {
                    print("🔍 Raw custom_categories value: \(user.custom_categories ?? "nil")")
                    
                    if let jsonString = user.custom_categories,
                       !jsonString.isEmpty,
                       let jsonData = jsonString.data(using: .utf8) {
                        let categories = try JSONDecoder().decode([CustomCategoryModel].self, from: jsonData)
                        print("✅ Loaded \(categories.count) custom categories (string format)")
                        print("🔍 Categories: \(categories)")
                        return categories
                    }
                }
            } catch let stringError {
                print("❌ String format also failed: \(stringError)")
                
                // ✅ Auto-reset to fix corrupted format
                print("🔧 Auto-resetting custom_categories...")
                do {
                    try await client
                        .from("users")
                        .update(["custom_categories": "[]"])
                        .eq("id", value: userId)
                        .execute()
                    print("✅ Reset complete")
                } catch {
                    print("❌ Reset failed: \(error)")
                }
            }
        }
        
        print("✅ Returning empty array")
        return []
    }
}

// MARK: - User Extension
extension User {
    var uid: String {
        id.uuidString
    }
    
    // Note: User already has 'email' property from Supabase
    // No need to override it
    
    var isEmailVerified: Bool {
        // Check if email is confirmed in Supabase
        return emailConfirmedAt != nil
    }
}
