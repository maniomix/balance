import Foundation
import SwiftUI
import Combine

// ============================================================
// MARK: - Forecast Engine
// ============================================================
//
// Deterministic, transparent forecasting for personal finance.
//
// Inputs:
//   - Current account balances (liquid assets only)
//   - Recurring transactions (upcoming bills/subscriptions)
//   - Budget plans (monthly budgets)
//   - Historical spending trends (3-month average)
//   - Historical income (3-month average)
//   - Active goal contributions
//
// Outputs:
//   - Projected balances at 30/60/90 day horizons
//   - Safe-to-spend amount
//   - Risk level (safe / caution / high risk)
//   - Day-by-day forecast timeline
//
// All amounts are in cents (Int) for precision.
// ============================================================

@MainActor
class ForecastEngine: ObservableObject {

    static let shared = ForecastEngine()

    @Published var forecast: ForecastResult?
    @Published var isLoading = false

    private init() {}

    // MARK: - Main Calculation

    /// Generate a complete forecast from current app state.
    /// Call this whenever data changes (transactions, budgets, accounts).
    func generate(store: Store) async {
        isLoading = true

        // Read goal data on MainActor before detaching to background
        let activeGoals = GoalManager.shared.activeGoals

        let result = await Task.detached(priority: .userInitiated) {
            Self.compute(store: store, activeGoals: activeGoals)
        }.value

        self.forecast = result
        isLoading = false
    }

    // MARK: - Pure Computation (off main thread)

    /// All calculations happen here. Pure function, no side effects.
    /// activeGoals is passed in to avoid @MainActor access from background.
    /// Uses store.selectedMonth as the reference month so results change
    /// when the user navigates between months.
    nonisolated static func compute(store: Store, activeGoals: [Goal]) -> ForecastResult {
        let cal = Calendar.current
        let realToday = Date()
        let selectedMonth = store.selectedMonth

        // Is the selected month the current real month?
        let isCurrentMonth = cal.isDate(realToday, equalTo: selectedMonth, toGranularity: .month)
        // Is the selected month in the past?
        let isPastMonth: Bool = {
            let selComps = cal.dateComponents([.year, .month], from: selectedMonth)
            let nowComps = cal.dateComponents([.year, .month], from: realToday)
            if let sy = selComps.year, let sm = selComps.month,
               let ny = nowComps.year, let nm = nowComps.month {
                return (sy * 12 + sm) < (ny * 12 + nm)
            }
            return false
        }()

        // Reference date: for current month use today, for past month use end of that month,
        // for future month use start of that month
        let referenceDate: Date
        if isCurrentMonth {
            referenceDate = realToday
        } else if isPastMonth {
            // Last day of the selected month
            let startOfNextMonth = cal.date(byAdding: .month, value: 1,
                to: cal.date(from: cal.dateComponents([.year, .month], from: selectedMonth))!)!
            referenceDate = cal.date(byAdding: .day, value: -1, to: startOfNextMonth)!
        } else {
            // Future month: first day of that month
            referenceDate = cal.date(from: cal.dateComponents([.year, .month], from: selectedMonth))!
        }

        // ─── Step 1: Gather historical data (3 months before the selected month) ───

        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: selectedMonth))!
        let threeMonthsAgo = cal.date(byAdding: .month, value: -3, to: monthStart)!
        let pastTransactions = store.transactions.filter { $0.date < monthStart && $0.date >= threeMonthsAgo }

        let monthsOfData = countDistinctMonths(transactions: pastTransactions, cal: cal)
        let divisor = max(1, monthsOfData)

        let totalExpenses3m = pastTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        let totalIncome3m = pastTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let avgMonthlyExpense = totalExpenses3m / divisor
        let avgMonthlyIncome = totalIncome3m / divisor

        // Average daily expense (for projection)
        let avgDailyExpense = avgMonthlyExpense / 30

        // ─── Step 2: Selected month state ───

        let selectedMonthTx = store.transactions.filter {
            cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }

        let spentThisMonth = selectedMonthTx
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        let incomeThisMonth = selectedMonthTx
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        let daysInMonth = cal.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30

        // Day of month and days remaining depend on whether this is current/past/future
        let dayOfMonth: Int
        let daysRemaining: Int

        if isCurrentMonth {
            dayOfMonth = cal.component(.day, from: realToday)
            daysRemaining = max(0, daysInMonth - dayOfMonth)
        } else if isPastMonth {
            // Past month: fully elapsed
            dayOfMonth = daysInMonth
            daysRemaining = 0
        } else {
            // Future month: nothing elapsed yet
            dayOfMonth = 0
            daysRemaining = daysInMonth
        }

        // Daily average spend (actual)
        let actualDailySpend = dayOfMonth > 0 ? spentThisMonth / dayOfMonth : 0

        // Use actual pace if we have enough data (7+ days in current month), else historical
        let projectionDailyRate: Int
        if isCurrentMonth && dayOfMonth >= 7 {
            projectionDailyRate = actualDailySpend
        } else {
            projectionDailyRate = avgDailyExpense
        }

        // ─── Step 3: Recurring transactions forecast ───

        let recurringExpenses = computeRecurringExpenses(
            recurring: store.recurringTransactions,
            from: referenceDate,
            days: 90,
            cal: cal
        )

        let monthlyRecurringExpense = recurringExpenses.monthly
        let next30Recurring = recurringExpenses.next30
        let next60Recurring = recurringExpenses.next60
        let next90Recurring = recurringExpenses.next90
        let upcomingBills = recurringExpenses.upcoming

        // ─── Step 4: Goal contributions ───

        let monthlyGoalContributions = activeGoals.compactMap { goal -> Int? in
            goal.requiredMonthlySaving
        }.reduce(0, +)

        // ─── Step 5: Budget for selected month ───

        let budget = store.budget(for: selectedMonth)

        // ─── Step 5b: Projected end-of-month balance ───

        let projectedMonthSpend: Int
        if isPastMonth {
            // Past month: actual spending IS the total
            projectedMonthSpend = spentThisMonth
        } else {
            projectedMonthSpend = spentThisMonth + (projectionDailyRate * daysRemaining)
        }
        let projectedMonthEnd = budget + incomeThisMonth - projectedMonthSpend

        // ─── Step 6: 30/60/90 day projections ───

        let monthlyNet = avgMonthlyIncome - avgMonthlyExpense - monthlyGoalContributions
        let currentRemaining = budget + incomeThisMonth - spentThisMonth

        let proj30: Int
        let proj60: Int
        let proj90: Int

        if isPastMonth {
            // Past month: no future projections, show actuals
            proj30 = currentRemaining
            proj60 = currentRemaining
            proj90 = currentRemaining
        } else {
            let daysInto30 = max(0, 30 - daysRemaining)
            proj30 = currentRemaining
                - (projectionDailyRate * daysRemaining)
                - (avgDailyExpense * daysInto30)
                + (avgMonthlyIncome * daysInto30 / 30)
                - next30Recurring
                + (daysRemaining > 0 ? 0 : avgMonthlyIncome)

            proj60 = proj30 + monthlyNet - next60Recurring + next30Recurring
            proj90 = proj60 + monthlyNet - next90Recurring + next60Recurring
        }

        // ─── Step 7: Safe to spend ───

        let safeToSpend = computeSafeToSpend(
            currentRemaining: currentRemaining,
            daysRemaining: daysRemaining,
            upcomingBills: upcomingBills,
            monthlyGoalContributions: monthlyGoalContributions,
            budget: budget
        )

        // ─── Step 8: Risk level ───

        let riskLevel = computeRiskLevel(
            safeToSpend: safeToSpend,
            projectedMonthEnd: projectedMonthEnd,
            budget: budget,
            spentRatio: budget > 0 ? Double(spentThisMonth) / Double(budget) : 0,
            dayRatio: daysInMonth > 0 ? Double(dayOfMonth) / Double(daysInMonth) : 0
        )

        // ─── Step 9: Timeline (daily projections for chart) ───

        let timeline: [ForecastPoint]
        if isPastMonth {
            // Past month: build timeline from actual daily spending
            timeline = computePastTimeline(
                transactions: selectedMonthTx,
                budget: budget,
                incomeThisMonth: incomeThisMonth,
                selectedMonth: selectedMonth,
                cal: cal
            )
        } else {
            timeline = computeTimeline(
                startBalance: currentRemaining,
                dailyExpense: projectionDailyRate,
                avgDailyIncome: avgMonthlyIncome / 30,
                recurring: store.recurringTransactions,
                days: isCurrentMonth ? 30 : daysInMonth,
                startDate: referenceDate,
                cal: cal
            )
        }

        // ─── Step 10: Spending breakdown ───

        let spendingByCategory = computeCategoryBreakdown(
            transactions: selectedMonthTx.filter { $0.type == .expense }
        )

        return ForecastResult(
            // Current state
            spentThisMonth: spentThisMonth,
            incomeThisMonth: incomeThisMonth,
            budget: budget,
            currentRemaining: currentRemaining,
            daysRemainingInMonth: daysRemaining,
            dayOfMonth: dayOfMonth,
            daysInMonth: daysInMonth,

            // Averages
            avgMonthlyExpense: avgMonthlyExpense,
            avgMonthlyIncome: avgMonthlyIncome,
            avgDailyExpense: projectionDailyRate,
            monthsOfData: monthsOfData,

            // Recurring
            monthlyRecurringExpense: monthlyRecurringExpense,
            upcomingBills: upcomingBills,

            // Goals
            monthlyGoalContributions: monthlyGoalContributions,

            // Projections
            projectedMonthEnd: projectedMonthEnd,
            projected30Day: proj30,
            projected60Day: proj60,
            projected90Day: proj90,

            // Safe to spend
            safeToSpend: safeToSpend,
            riskLevel: riskLevel,

            // Timeline
            timeline: timeline,

            // Breakdown
            topCategories: spendingByCategory,

            generatedAt: realToday
        )
    }

    // MARK: - Recurring Expenses Projection

    private struct RecurringForecast {
        let monthly: Int
        let next30: Int
        let next60: Int
        let next90: Int
        let upcoming: [UpcomingBill]
    }

    nonisolated private static func computeRecurringExpenses(
        recurring: [RecurringTransaction],
        from start: Date,
        days: Int,
        cal: Calendar
    ) -> RecurringForecast {

        let active = recurring.filter { $0.isActive }
        var total30 = 0
        var total60 = 0
        var total90 = 0
        var monthly = 0
        var bills: [UpcomingBill] = []

        let end30 = cal.date(byAdding: .day, value: 30, to: start)!
        let end60 = cal.date(byAdding: .day, value: 60, to: start)!
        let end90 = cal.date(byAdding: .day, value: 90, to: start)!

        for item in active {
            // Estimate monthly cost
            switch item.frequency {
            case .daily: monthly += item.amount * 30
            case .weekly: monthly += item.amount * 4
            case .monthly: monthly += item.amount
            case .yearly: monthly += item.amount / 12
            }

            // Project occurrences in each window
            var date = item.nextOccurrence(from: start) ?? start
            var count30 = 0
            var count60 = 0
            var count90 = 0

            while date <= end90 {
                if date <= end30 {
                    count30 += 1
                    // Track as upcoming bill
                    if bills.count < 20 && date <= end30 {
                        bills.append(UpcomingBill(
                            name: item.name,
                            amount: item.amount,
                            dueDate: date,
                            category: item.category,
                            isRecurring: true
                        ))
                    }
                }
                if date <= end60 { count60 += 1 }
                count90 += 1

                // Advance to next occurrence
                guard let next = advanceDate(date, frequency: item.frequency, cal: cal) else { break }
                if next <= date { break } // Safety: prevent infinite loop
                date = next
            }

            total30 += item.amount * count30
            total60 += item.amount * count60
            total90 += item.amount * count90
        }

        bills.sort { $0.dueDate < $1.dueDate }

        return RecurringForecast(
            monthly: monthly,
            next30: total30,
            next60: total60,
            next90: total90,
            upcoming: bills
        )
    }

    nonisolated private static func advanceDate(_ date: Date, frequency: RecurringFrequency, cal: Calendar) -> Date? {
        switch frequency {
        case .daily: return cal.date(byAdding: .day, value: 1, to: date)
        case .weekly: return cal.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly: return cal.date(byAdding: .month, value: 1, to: date)
        case .yearly: return cal.date(byAdding: .year, value: 1, to: date)
        }
    }

    // MARK: - Safe to Spend

    /// Safe to spend = what you can spend today without jeopardizing
    /// bills, goal contributions, or budget limits.
    ///
    /// Formula:
    ///   remaining_budget
    ///   - upcoming_bills_this_month
    ///   - remaining_goal_contributions_this_month
    ///   = safe_to_spend
    ///
    /// Then divide by days remaining to get daily safe amount.
    nonisolated private static func computeSafeToSpend(
        currentRemaining: Int,
        daysRemaining: Int,
        upcomingBills: [UpcomingBill],
        monthlyGoalContributions: Int,
        budget: Int
    ) -> SafeToSpend {

        // Upcoming bills due within the remaining days
        let billsThisMonth = upcomingBills
            .prefix(20) // already filtered in computeRecurringExpenses
            .reduce(0) { $0 + $1.amount }

        // Goal contributions remaining for this month (assume not yet contributed)
        let goalReserve = monthlyGoalContributions

        // Total amount
        let totalSafe = max(0, currentRemaining - billsThisMonth - goalReserve)

        // Per day
        let perDay = daysRemaining > 0 ? totalSafe / daysRemaining : totalSafe

        return SafeToSpend(
            totalAmount: totalSafe,
            perDay: perDay,
            daysRemaining: daysRemaining,
            reservedForBills: billsThisMonth,
            reservedForGoals: goalReserve,
            budgetRemaining: currentRemaining
        )
    }

    // MARK: - Risk Level

    /// Determine risk level from multiple signals.
    ///
    /// SAFE:    spending on pace, positive projections
    /// CAUTION: spending slightly ahead, or low remaining
    /// HIGH RISK: over budget or negative projections
    nonisolated private static func computeRiskLevel(
        safeToSpend: SafeToSpend,
        projectedMonthEnd: Int,
        budget: Int,
        spentRatio: Double,
        dayRatio: Double
    ) -> RiskLevel {

        // Already overspent
        if safeToSpend.totalAmount <= 0 { return .highRisk }

        // Projected to overshoot budget
        if projectedMonthEnd < 0 { return .highRisk }

        // Spending faster than time passing
        if spentRatio > 0 && dayRatio > 0 {
            let paceRatio = spentRatio / dayRatio
            if paceRatio > 1.3 { return .highRisk }
            if paceRatio > 1.05 { return .caution }
        }

        // Low safe-to-spend per day (less than 5% of budget)
        if budget > 0 && safeToSpend.perDay < budget / 20 {
            return .caution
        }

        return .safe
    }

    // MARK: - Timeline

    /// Daily balance projection for chart
    nonisolated private static func computeTimeline(
        startBalance: Int,
        dailyExpense: Int,
        avgDailyIncome: Int,
        recurring: [RecurringTransaction],
        days: Int,
        startDate: Date,
        cal: Calendar
    ) -> [ForecastPoint] {

        var points: [ForecastPoint] = []
        var balance = startBalance

        for i in 0..<days {
            guard let date = cal.date(byAdding: .day, value: i, to: startDate) else { continue }

            // Check for recurring transaction on this day
            var recurringHit = 0
            for item in recurring where item.isActive {
                if let next = item.nextOccurrence(from: cal.date(byAdding: .day, value: -1, to: date)!) {
                    if cal.isDate(next, inSameDayAs: date) {
                        recurringHit += item.amount
                    }
                }
            }

            // Daily change: income - spending - recurring
            let dailyNet = avgDailyIncome - dailyExpense - recurringHit
            if i > 0 { balance += dailyNet }

            points.append(ForecastPoint(
                date: date,
                balance: balance,
                dayIndex: i
            ))
        }

        return points
    }

    /// Build a timeline from actual transactions for a past (completed) month.
    /// Shows how the balance changed day by day based on real data.
    nonisolated private static func computePastTimeline(
        transactions: [Transaction],
        budget: Int,
        incomeThisMonth: Int,
        selectedMonth: Date,
        cal: Calendar
    ) -> [ForecastPoint] {
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: selectedMonth))!
        let daysInMonth = cal.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30

        // Group spending by day
        var dailyExpense: [Int: Int] = [:]   // day number -> total expense
        var dailyIncome: [Int: Int] = [:]    // day number -> total income
        for tx in transactions {
            let day = cal.component(.day, from: tx.date)
            if tx.type == .expense {
                dailyExpense[day, default: 0] += tx.amount
            } else {
                dailyIncome[day, default: 0] += tx.amount
            }
        }

        var points: [ForecastPoint] = []
        var balance = budget + incomeThisMonth // start with full budget
        // Actually compute running balance: budget - cumulative spending + cumulative income
        var cumulativeSpent = 0
        var cumulativeIncome = 0

        for day in 1...daysInMonth {
            cumulativeSpent += dailyExpense[day] ?? 0
            cumulativeIncome += dailyIncome[day] ?? 0
            balance = budget + cumulativeIncome - cumulativeSpent

            guard let date = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            points.append(ForecastPoint(
                date: date,
                balance: balance,
                dayIndex: day - 1
            ))
        }

        return points
    }

    // MARK: - Category Breakdown

    nonisolated private static func computeCategoryBreakdown(transactions: [Transaction]) -> [CategorySpend] {
        var byCategory: [String: Int] = [:]

        for tx in transactions {
            let key = tx.category.title
            byCategory[key, default: 0] += tx.amount
        }

        let total = max(1, transactions.reduce(0) { $0 + $1.amount })

        return byCategory
            .map { CategorySpend(name: $0.key, amount: $0.value, percentage: Double($0.value) / Double(total)) }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Helpers

    nonisolated private static func countDistinctMonths(transactions: [Transaction], cal: Calendar) -> Int {
        var months = Set<String>()
        for tx in transactions {
            let y = cal.component(.year, from: tx.date)
            let m = cal.component(.month, from: tx.date)
            months.insert("\(y)-\(m)")
        }
        return months.count
    }
}

// ============================================================
// MARK: - Data Models
// ============================================================

struct ForecastResult {
    // Current state
    let spentThisMonth: Int
    let incomeThisMonth: Int
    let budget: Int
    let currentRemaining: Int
    let daysRemainingInMonth: Int
    let dayOfMonth: Int
    let daysInMonth: Int

    // Historical averages
    let avgMonthlyExpense: Int
    let avgMonthlyIncome: Int
    let avgDailyExpense: Int
    let monthsOfData: Int

    // Recurring
    let monthlyRecurringExpense: Int
    let upcomingBills: [UpcomingBill]

    // Goals
    let monthlyGoalContributions: Int

    // Projections
    let projectedMonthEnd: Int
    let projected30Day: Int
    let projected60Day: Int
    let projected90Day: Int

    // Safe to spend
    let safeToSpend: SafeToSpend
    let riskLevel: RiskLevel

    // Timeline (day-by-day for chart)
    let timeline: [ForecastPoint]

    // Top spending categories
    let topCategories: [CategorySpend]

    let generatedAt: Date

    // Convenience
    var monthProgressRatio: Double {
        guard daysInMonth > 0 else { return 0 }
        return Double(dayOfMonth) / Double(daysInMonth)
    }

    var spentRatio: Double {
        guard budget > 0 else { return 0 }
        return Double(spentThisMonth) / Double(budget)
    }
}

struct SafeToSpend {
    let totalAmount: Int      // Total you can safely spend
    let perDay: Int           // Daily safe amount
    let daysRemaining: Int
    let reservedForBills: Int
    let reservedForGoals: Int
    let budgetRemaining: Int
}

struct UpcomingBill: Identifiable {
    let id = UUID()
    let name: String
    let amount: Int
    let dueDate: Date
    let category: Category
    let isRecurring: Bool
}

struct ForecastPoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Int
    let dayIndex: Int
}

struct CategorySpend: Identifiable {
    let id = UUID()
    let name: String
    let amount: Int
    let percentage: Double
}

enum RiskLevel {
    case safe, caution, highRisk

    var label: String {
        switch self {
        case .safe: return "Safe"
        case .caution: return "Caution"
        case .highRisk: return "High Risk"
        }
    }

    var icon: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .highRisk: return "xmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .safe: return DS.Colors.positive
        case .caution: return DS.Colors.warning
        case .highRisk: return DS.Colors.danger
        }
    }
}
