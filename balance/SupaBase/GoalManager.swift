import Foundation
import Supabase
import Combine

// MARK: - Goal Manager

@MainActor
class GoalManager: ObservableObject {
    
    static let shared = GoalManager()
    
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    private var currentUserId: String? {
        AuthManager.shared.currentUser?.uid
    }
    
    private init() {}
    
    // MARK: - Fetch Goals
    
    func fetchGoals() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        
        do {
            let response: [Goal] = try await client
                .from("goals")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.goals = response
            print("✅ Fetched \(response.count) goals")
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Fetch goals failed: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Create Goal
    
    func createGoal(_ goal: Goal) async -> Bool {
        do {
            try await client.from("goals").insert(goal).execute()
            print("✅ Goal created: \(goal.name)")
            await fetchGoals()
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Create goal failed: \(error)")
            return false
        }
    }
    
    // MARK: - Update Goal
    
    func updateGoal(_ goal: Goal) async -> Bool {
        var updated = goal
        updated.updatedAt = Date()
        
        do {
            try await client.from("goals")
                .update(updated)
                .eq("id", value: updated.id.uuidString)
                .execute()
            await fetchGoals()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Delete Goal
    
    func deleteGoal(_ goal: Goal) async -> Bool {
        do {
            // Delete contributions first
            try await client.from("goal_contributions")
                .delete()
                .eq("goal_id", value: goal.id.uuidString)
                .execute()
            
            try await client.from("goals")
                .delete()
                .eq("id", value: goal.id.uuidString)
                .execute()
            
            await fetchGoals()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Contributions
    
    func addContribution(to goal: Goal, amount: Int, note: String? = nil, source: GoalContribution.ContributionSource = .manual) async -> Bool {
        let contribution = GoalContribution(
            goalId: goal.id,
            amount: amount,
            note: note,
            source: source
        )
        
        do {
            try await client.from("goal_contributions").insert(contribution).execute()
            
            // Update goal's current amount
            var updated = goal
            updated.currentAmount += amount
            if updated.currentAmount >= updated.targetAmount {
                updated.isCompleted = true
            }
            updated.updatedAt = Date()
            
            try await client.from("goals")
                .update(updated)
                .eq("id", value: updated.id.uuidString)
                .execute()
            
            await fetchGoals()
            print("✅ Contribution added: \(amount) cents to \(goal.name)")
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func fetchContributions(for goal: Goal) async -> [GoalContribution] {
        do {
            let response: [GoalContribution] = try await client
                .from("goal_contributions")
                .select()
                .eq("goal_id", value: goal.id.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            return response
        } catch {
            return []
        }
    }
    
    // MARK: - Projections
    
    /// Average monthly contribution for a goal based on its history
    func averageMonthlyContribution(for goal: Goal) async -> Int {
        let contributions = await fetchContributions(for: goal)
        guard !contributions.isEmpty else { return 0 }
        
        let total = contributions.reduce(0) { $0 + $1.amount }
        let months = max(1, Calendar.current.dateComponents(
            [.month], from: goal.createdAt, to: Date()
        ).month ?? 1)
        
        return total / months
    }
    
    // MARK: - Computed
    
    var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    var totalSaved: Int {
        goals.reduce(0) { $0 + $1.currentAmount }
    }
    
    var totalTarget: Int {
        goals.reduce(0) { $0 + $1.targetAmount }
    }
    
    /// Goals with upcoming deadlines (next 30 days)
    var upcomingDeadlines: [Goal] {
        let thirtyDays = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return activeGoals.filter { goal in
            guard let target = goal.targetDate else { return false }
            return target <= thirtyDays && target >= Date()
        }.sorted { ($0.targetDate ?? .distantFuture) < ($1.targetDate ?? .distantFuture) }
    }
}
