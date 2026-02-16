import Foundation
import Supabase
import SwiftUI

// MARK: - Supabase Manager
@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private var client: SupabaseClient!
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    init() {
        setupClient()
    }
    
    private func setupClient() {
        // Load from Supabase.plist
        guard let path = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let url = config["SUPABASE_URL"] as? String,
              let anonKey = config["SUPABASE_ANON_KEY"] as? String else {
            fatalError("Missing Supabase.plist")
        }
        
        client = SupabaseClient(
            supabaseURL: URL(string: url)!,
            supabaseKey: anonKey
        )
        
        // Listen for auth changes
        Task {
            for await state in await client.auth.authStateChanges {
                self.currentUser = state.session?.user
                self.isAuthenticated = state.session != nil
            }
        }
    }
    
    // MARK: - Auth
    
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    // MARK: - Transactions
    
    func saveTransaction(_ transaction: Transaction, userId: String) async throws {
        let data: [String: Any] = [
            "id": transaction.id.uuidString,
            "user_id": userId,
            "amount": transaction.amount,
            "category": transaction.category.storageKey,
            "type": transaction.type == .income ? "income" : "expense",
            "note": transaction.note,
            "date": ISO8601DateFormatter().string(from: transaction.date)
        ]
        
        try await client.database
            .from("transactions")
            .upsert(data)
            .execute()
    }
    
    func loadTransactions(userId: String) async throws -> [Transaction] {
        let response: [TransactionDTO] = try await client.database
            .from("transactions")
            .select()
            .eq("user_id", value: userId)
            .eq("is_deleted", value: false)
            .order("date", ascending: false)
            .execute()
            .value
        
        return response.compactMap { $0.toTransaction() }
    }
    
    func deleteTransaction(_ transactionId: UUID) async throws {
        try await client.database
            .from("transactions")
            .update(["is_deleted": true])
            .eq("id", value: transactionId.uuidString)
            .execute()
    }
    
    // MARK: - Budgets
    
    func saveBudget(userId: String, month: Date, amount: Int) async throws {
        let monthStr = ISO8601DateFormatter().string(from: month)
        
        try await client.database
            .from("budgets")
            .upsert([
                "user_id": userId,
                "month": monthStr,
                "total_amount": amount
            ])
            .execute()
    }
    
    func loadBudgets(userId: String) async throws -> [String: Int] {
        let response: [BudgetDTO] = try await client.database
            .from("budgets")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        var budgets: [String: Int] = [:]
        for budget in response {
            budgets[budget.month] = budget.total_amount
        }
        return budgets
    }
    
    // MARK: - Real-time Sync
    
    func subscribeToTransactions(userId: String, onChange: @escaping ([Transaction]) -> Void) {
        let channel = client.channel("transactions:\(userId)")
        
        channel
            .on(.postgresChanges(
                event: .all,
                schema: "public",
                table: "transactions",
                filter: "user_id=eq.\(userId)"
            )) { _ in
                Task {
                    let transactions = try await self.loadTransactions(userId: userId)
                    await MainActor.run {
                        onChange(transactions)
                    }
                }
            }
            .subscribe()
    }
    
    // MARK: - Analytics
    
    func trackEvent(name: String, properties: [String: Any]? = nil) async throws {
        guard let userId = currentUser?.id.uuidString else { return }
        
        var data: [String: Any] = [
            "user_id": userId,
            "event_name": name
        ]
        
        if let props = properties {
            data["event_properties"] = props
        }
        
        try await client.database
            .from("events")
            .insert(data)
            .execute()
    }
    
    func updateLastActive() async throws {
        guard let userId = currentUser?.id.uuidString else { return }
        
        try await client.database
            .from("users")
            .update(["last_active_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: userId)
            .execute()
    }
}

// MARK: - DTOs
struct TransactionDTO: Codable {
    let id: String
    let user_id: String
    let amount: Int
    let category: String
    let type: String
    let note: String?
    let date: String
    
    func toTransaction() -> Transaction? {
        guard let uuid = UUID(uuidString: id),
              let date = ISO8601DateFormatter().date(from: self.date) else {
            return nil
        }
        
        return Transaction(
            id: uuid,
            amount: amount,
            category: Category.from(storageKey: category) ?? .other,
            type: type == "income" ? .income : .expense,
            note: note ?? "",
            date: date
        )
    }
}

struct BudgetDTO: Codable {
    let month: String
    let total_amount: Int
}

// MARK: - User Model Extension
extension User {
    var uid: String {
        id.uuidString
    }
}
