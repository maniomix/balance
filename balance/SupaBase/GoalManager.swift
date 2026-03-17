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
            SecureLogger.info("Fetched \(response.count) goals")
        } catch {
            self.errorMessage = AppConfig.shared.safeErrorMessage(
                detail: error.localizedDescription,
                fallback: "Could not load goals. Please try again."
            )
            SecureLogger.error("Fetch goals failed", error)
        }

        isLoading = false
    }

    // MARK: - Create Goal

    func createGoal(_ goal: Goal) async -> Bool {
        do {
            try await client.from("goals").insert(goal).execute()
            SecureLogger.info("Goal created")
            AnalyticsManager.shared.track(.goalCreated)
            AnalyticsManager.shared.checkFirstGoal()
            await fetchGoals()
            return true
        } catch {
            errorMessage = AppConfig.shared.safeErrorMessage(
                detail: error.localizedDescription,
                fallback: "Could not create goal. Please try again."
            )
            SecureLogger.error("Create goal failed", error)
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
            errorMessage = AppConfig.shared.safeErrorMessage(detail: error.localizedDescription)
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
            errorMessage = AppConfig.shared.safeErrorMessage(detail: error.localizedDescription)
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
                AnalyticsManager.shared.track(.goalCompleted)
            }
            AnalyticsManager.shared.track(.goalContribution)
            updated.updatedAt = Date()

            try await client.from("goals")
                .update(updated)
                .eq("id", value: updated.id.uuidString)
                .execute()

            await fetchGoals()
            SecureLogger.info("Goal contribution added")
            return true
        } catch {
            errorMessage = AppConfig.shared.safeErrorMessage(detail: error.localizedDescription)
            return false
        }
    }

    /// Withdraw from a goal (negative contribution)
    func withdrawContribution(from goal: Goal, amount: Int, note: String? = nil) async -> Bool {
        let withdrawAmount = min(amount, goal.currentAmount)
        guard withdrawAmount > 0 else { return false }

        let contribution = GoalContribution(
            goalId: goal.id,
            amount: -withdrawAmount,
            note: note ?? "Withdrawal",
            source: .manual
        )

        do {
            try await client.from("goal_contributions").insert(contribution).execute()

            var updated = goal
            updated.currentAmount = max(0, updated.currentAmount - withdrawAmount)
            updated.isCompleted = false
            updated.updatedAt = Date()

            try await client.from("goals")
                .update(updated)
                .eq("id", value: updated.id.uuidString)
                .execute()

            await fetchGoals()
            SecureLogger.info("Goal withdrawal processed")
            return true
        } catch {
            errorMessage = AppConfig.shared.safeErrorMessage(detail: error.localizedDescription)
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
        let positiveOnly = contributions.filter { $0.amount > 0 }
        guard !positiveOnly.isEmpty else { return 0 }

        let total = positiveOnly.reduce(0) { $0 + $1.amount }
        let months = max(1, Calendar.current.dateComponents(
            [.month], from: goal.createdAt, to: Date()
        ).month ?? 1)

        return total / months
    }

    /// Detailed projection for a goal
    func projection(for goal: Goal) async -> GoalProjection {
        let avgMonthly = await averageMonthlyContribution(for: goal)
        let contributions = await fetchContributions(for: goal)

        let totalContributed = contributions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        let totalWithdrawn = contributions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
        let contributionCount = contributions.count

        // Average per contribution
        let positiveContributions = contributions.filter { $0.amount > 0 }
        let avgPerContribution = positiveContributions.isEmpty ? 0 : totalContributed / positiveContributions.count

        // Weekly rate (last 4 weeks)
        let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        let recentTotal = contributions
            .filter { $0.amount > 0 && $0.createdAt >= fourWeeksAgo }
            .reduce(0) { $0 + $1.amount }
        let weeklyRate = recentTotal / 4

        // Estimated completion
        let estimatedDate = goal.estimatedCompletion(averageMonthly: avgMonthly)

        // On-track assessment
        let onTrackPace: Int? = {
            guard goal.targetDate != nil else { return nil }
            return goal.requiredMonthlySaving
        }()

        let paceStatus: GoalProjection.PaceStatus = {
            guard let required = onTrackPace, required > 0 else {
                if goal.isCompleted { return .completed }
                return .noDeadline
            }
            if avgMonthly == 0 { return .behind }
            let ratio = Double(avgMonthly) / Double(required)
            if ratio >= 1.1 { return .ahead }
            if ratio >= 0.9 { return .onTrack }
            return .behind
        }()

        return GoalProjection(
            averageMonthly: avgMonthly,
            averagePerContribution: avgPerContribution,
            weeklyRate: weeklyRate,
            totalContributed: totalContributed,
            totalWithdrawn: totalWithdrawn,
            contributionCount: contributionCount,
            estimatedCompletion: estimatedDate,
            requiredMonthly: goal.requiredMonthlySaving,
            paceStatus: paceStatus
        )
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

    var overallProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return min(Double(totalSaved) / Double(totalTarget), 1.0)
    }

    /// Goals with upcoming deadlines (next 30 days)
    var upcomingDeadlines: [Goal] {
        let thirtyDays = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return activeGoals.filter { goal in
            guard let target = goal.targetDate else { return false }
            return target <= thirtyDays && target >= Date()
        }.sorted { ($0.targetDate ?? .distantFuture) < ($1.targetDate ?? .distantFuture) }
    }

    /// Goals sorted by urgency (closest deadline first, then by progress)
    var goalsByPriority: [Goal] {
        activeGoals.sorted { a, b in
            // Goals with deadlines first
            if a.targetDate != nil && b.targetDate == nil { return true }
            if a.targetDate == nil && b.targetDate != nil { return false }
            // Both have deadlines: closest first
            if let ad = a.targetDate, let bd = b.targetDate { return ad < bd }
            // Both no deadline: lowest progress first
            return a.progress < b.progress
        }
    }

    /// Goals that are behind schedule
    var behindGoals: [Goal] {
        activeGoals.filter { $0.trackingStatus == .behind }
    }
}

// MARK: - Goal Projection Model

struct GoalProjection {
    let averageMonthly: Int
    let averagePerContribution: Int
    let weeklyRate: Int
    let totalContributed: Int
    let totalWithdrawn: Int
    let contributionCount: Int
    let estimatedCompletion: Date?
    let requiredMonthly: Int?
    let paceStatus: PaceStatus

    enum PaceStatus {
        case ahead, onTrack, behind, completed, noDeadline

        var label: String {
            switch self {
            case .ahead: return "Ahead of schedule"
            case .onTrack: return "On track"
            case .behind: return "Behind schedule"
            case .completed: return "Completed"
            case .noDeadline: return "No deadline"
            }
        }

        var icon: String {
            switch self {
            case .ahead: return "arrow.up.right"
            case .onTrack: return "checkmark.circle"
            case .behind: return "exclamationmark.triangle"
            case .completed: return "checkmark.circle.fill"
            case .noDeadline: return "clock"
            }
        }
    }
}
