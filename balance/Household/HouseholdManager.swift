import Foundation
import Combine

// ============================================================
// MARK: - Household Manager
// ============================================================
// Singleton managing the household state, split expenses,
// settlements, and shared budgets.
// Persists locally via UserDefaults (keyed by userId).
// Single-user mode: household == nil → all features hidden.
// ============================================================

@MainActor
class HouseholdManager: ObservableObject {

    static let shared = HouseholdManager()

    // MARK: - Published State

    @Published var household: Household?
    @Published var sharedBudgets: [SharedBudget] = []
    @Published var splitExpenses: [SplitExpense] = []
    @Published var settlements: [Settlement] = []
    @Published var sharedGoals: [SharedGoal] = []
    @Published var pendingInvites: [HouseholdInvite] = []
    @Published var isLoading: Bool = false

    private var userId: String = ""
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // ============================================================
    // MARK: - Lifecycle
    // ============================================================

    func load(userId: String) {
        self.userId = userId
        household = loadData("household_\(userId)")
        sharedBudgets = loadData("shared_budgets_\(userId)") ?? []
        splitExpenses = loadData("split_expenses_\(userId)") ?? []
        settlements = loadData("settlements_\(userId)") ?? []
        sharedGoals = loadData("shared_goals_\(userId)") ?? []
        pendingInvites = loadData("household_invites_\(userId)") ?? []
    }

    func save() {
        guard !userId.isEmpty else { return }
        saveData(household, key: "household_\(userId)")
        saveData(sharedBudgets, key: "shared_budgets_\(userId)")
        saveData(splitExpenses, key: "split_expenses_\(userId)")
        saveData(settlements, key: "settlements_\(userId)")
        saveData(sharedGoals, key: "shared_goals_\(userId)")
        saveData(pendingInvites, key: "household_invites_\(userId)")
    }

    // ============================================================
    // MARK: - Household CRUD
    // ============================================================

    func createHousehold(name: String, ownerName: String, ownerEmail: String) {
        let owner = HouseholdMember(
            userId: userId,
            displayName: ownerName,
            email: ownerEmail,
            role: .owner,
            sharedAccountIds: nil,
            shareTransactions: true
        )
        household = Household(
            name: name,
            createdBy: userId,
            members: [owner]
        )
        save()
        AnalyticsManager.shared.track(.householdCreated)
    }

    func updateHouseholdName(_ name: String) {
        household?.name = name
        household?.updatedAt = Date()
        save()
    }

    func deleteHousehold() {
        household = nil
        sharedBudgets = []
        splitExpenses = []
        settlements = []
        sharedGoals = []
        pendingInvites = []
        save()
    }

    // ============================================================
    // MARK: - Invites
    // ============================================================

    func generateInvite(role: HouseholdRole = .partner) -> HouseholdInvite? {
        guard let h = household else { return nil }
        let invite = HouseholdInvite(
            householdId: h.id,
            invitedBy: userId,
            inviteCode: h.inviteCode,
            role: role
        )
        pendingInvites.append(invite)
        save()
        return invite
    }

    func joinHousehold(code: String, displayName: String, email: String) -> Bool {
        // In a real app this would be a server call.
        // For local mode we simulate: find household with matching code.
        guard var h = household, h.inviteCode.uppercased() == code.uppercased() else {
            return false
        }
        // Check not already a member
        guard h.member(for: userId) == nil else { return true }

        let member = HouseholdMember(
            userId: userId,
            displayName: displayName,
            email: email,
            role: .partner,
            shareTransactions: true
        )
        h.members.append(member)
        h.updatedAt = Date()
        household = h
        save()
        AnalyticsManager.shared.track(.householdJoined)
        return true
    }

    func removeMember(userId targetId: String) {
        guard var h = household, h.createdBy == userId else { return }
        h.members.removeAll { $0.userId == targetId }
        h.updatedAt = Date()
        household = h
        save()
    }

    func updateMemberRole(userId targetId: String, role: HouseholdRole) {
        guard var h = household, h.canEdit(userId: userId) else { return }
        if let idx = h.members.firstIndex(where: { $0.userId == targetId }) {
            h.members[idx].role = role
            h.updatedAt = Date()
            household = h
            save()
        }
    }

    // ============================================================
    // MARK: - Privacy / Visibility
    // ============================================================

    func updatePrivacy(shareTransactions: Bool, sharedAccountIds: [String]?) {
        guard var h = household,
              let idx = h.members.firstIndex(where: { $0.userId == userId }) else { return }
        h.members[idx].shareTransactions = shareTransactions
        h.members[idx].sharedAccountIds = sharedAccountIds
        h.updatedAt = Date()
        household = h
        save()
    }

    /// Whether this user is in a household.
    var isInHousehold: Bool { household != nil }

    /// Current member record.
    var currentMember: HouseholdMember? { household?.member(for: userId) }

    // ============================================================
    // MARK: - Shared Budgets
    // ============================================================

    func setSharedBudget(monthKey: String, amount: Int, splitRule: SplitRule = .equal) {
        guard let h = household else { return }
        if let idx = sharedBudgets.firstIndex(where: { $0.householdId == h.id && $0.monthKey == monthKey }) {
            sharedBudgets[idx].totalAmount = amount
            sharedBudgets[idx].splitRule = splitRule
            sharedBudgets[idx].updatedAt = Date()
        } else {
            let sb = SharedBudget(
                householdId: h.id,
                monthKey: monthKey,
                totalAmount: amount,
                splitRule: splitRule
            )
            sharedBudgets.append(sb)
        }
        save()
    }

    func sharedBudget(for monthKey: String) -> SharedBudget? {
        guard let h = household else { return nil }
        return sharedBudgets.first(where: { $0.householdId == h.id && $0.monthKey == monthKey })
    }

    // ============================================================
    // MARK: - Split Expenses
    // ============================================================

    func addSplitExpense(
        amount: Int,
        paidBy: String,
        splitRule: SplitRule,
        customSplits: [MemberSplit] = [],
        category: String = "other",
        note: String = "",
        date: Date = Date(),
        transactionId: UUID = UUID()
    ) {
        guard let h = household else { return }
        let expense = SplitExpense(
            householdId: h.id,
            transactionId: transactionId,
            amount: amount,
            paidBy: paidBy,
            splitRule: splitRule,
            customSplits: customSplits,
            category: category,
            note: note,
            date: date
        )
        splitExpenses.append(expense)
        save()
    }

    func removeSplitExpense(id: UUID) {
        splitExpenses.removeAll { $0.id == id }
        save()
    }

    func markExpenseSettled(id: UUID) {
        if let idx = splitExpenses.firstIndex(where: { $0.id == id }) {
            splitExpenses[idx].isSettled = true
            splitExpenses[idx].settledAt = Date()
            save()
        }
    }

    /// Unsettled expenses for current household.
    var unsettledExpenses: [SplitExpense] {
        guard let h = household else { return [] }
        return splitExpenses.filter { $0.householdId == h.id && !$0.isSettled }
    }

    /// Net balance between two members.
    /// Positive = fromUser owes toUser.
    func netBalance(fromUser: String, toUser: String) -> Int {
        guard let h = household else { return 0 }
        let members = h.members
        var balance: Int = 0

        for expense in unsettledExpenses {
            let splits = expense.splits(members: members)
            if expense.paidBy == toUser {
                // toUser paid → fromUser owes their share
                let fromShare = splits.first(where: { $0.userId == fromUser })?.amount ?? 0
                balance += fromShare
            } else if expense.paidBy == fromUser {
                // fromUser paid → toUser owes their share
                let toShare = splits.first(where: { $0.userId == toUser })?.amount ?? 0
                balance -= toShare
            }
        }
        return balance
    }

    // ============================================================
    // MARK: - Settlements
    // ============================================================

    func settleUp(fromUser: String, toUser: String, amount: Int, note: String = "") {
        guard let h = household else { return }
        // Mark matching expenses as settled
        let expenseIds = unsettledExpenses
            .filter { $0.paidBy == toUser || $0.paidBy == fromUser }
            .map { $0.id }

        let settlement = Settlement(
            householdId: h.id,
            fromUserId: fromUser,
            toUserId: toUser,
            amount: amount,
            note: note.isEmpty ? "Settlement" : note,
            relatedExpenseIds: expenseIds
        )
        settlements.append(settlement)

        // Mark related expenses as settled
        for eid in expenseIds {
            markExpenseSettled(id: eid)
        }
        save()
    }

    // ============================================================
    // MARK: - Shared Goals
    // ============================================================

    func addSharedGoal(name: String, icon: String = "star.fill", targetAmount: Int) {
        guard let h = household, h.canEdit(userId: userId) else { return }
        let goal = SharedGoal(
            householdId: h.id,
            name: name,
            icon: icon,
            targetAmount: targetAmount,
            createdBy: userId
        )
        sharedGoals.append(goal)
        save()
    }

    func updateSharedGoal(id: UUID, name: String? = nil, icon: String? = nil, targetAmount: Int? = nil) {
        guard let h = household, h.canEdit(userId: userId) else { return }
        guard let idx = sharedGoals.firstIndex(where: { $0.id == id && $0.householdId == h.id }) else { return }
        if let name = name { sharedGoals[idx].name = name }
        if let icon = icon { sharedGoals[idx].icon = icon }
        if let targetAmount = targetAmount { sharedGoals[idx].targetAmount = targetAmount }
        sharedGoals[idx].updatedAt = Date()
        save()
    }

    func contributeToSharedGoal(id: UUID, amount: Int) {
        guard let h = household else { return }
        guard let idx = sharedGoals.firstIndex(where: { $0.id == id && $0.householdId == h.id }) else { return }
        sharedGoals[idx].currentAmount += amount
        sharedGoals[idx].updatedAt = Date()
        save()
    }

    func removeSharedGoal(id: UUID) {
        guard let h = household, h.canEdit(userId: userId) else { return }
        sharedGoals.removeAll { $0.id == id && $0.householdId == h.id }
        save()
    }

    /// Active (non-completed) shared goals for the current household.
    var activeSharedGoals: [SharedGoal] {
        guard let h = household else { return [] }
        return sharedGoals.filter { $0.householdId == h.id && !$0.isCompleted }
    }

    // ============================================================
    // MARK: - Summary / Analytics
    // ============================================================

    /// Total shared spending this month.
    func sharedSpending(monthKey: String) -> Int {
        guard let h = household else { return 0 }
        return splitExpenses
            .filter { $0.householdId == h.id && Store.monthKey($0.date) == monthKey }
            .reduce(0) { $0 + $1.amount }
    }

    /// Per-member spending this month.
    func memberSpending(monthKey: String) -> [String: Int] {
        guard let h = household else { return [:] }
        var result: [String: Int] = [:]
        for expense in splitExpenses where expense.householdId == h.id && Store.monthKey(expense.date) == monthKey {
            let splits = expense.splits(members: h.members)
            for s in splits {
                result[s.userId, default: 0] += s.amount
            }
        }
        return result
    }

    /// Category breakdown for shared expenses.
    func sharedCategoryBreakdown(monthKey: String) -> [String: Int] {
        guard let h = household else { return [:] }
        var result: [String: Int] = [:]
        for expense in splitExpenses where expense.householdId == h.id && Store.monthKey(expense.date) == monthKey {
            result[expense.category, default: 0] += expense.amount
        }
        return result
    }

    // ============================================================
    // MARK: - Persistence Helpers
    // ============================================================

    private func saveData<T: Encodable>(_ value: T, key: String) {
        if let data = try? encoder.encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadData<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}
