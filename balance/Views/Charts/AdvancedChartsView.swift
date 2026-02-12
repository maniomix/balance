import SwiftUI
import Charts

// MARK: - Advanced Charts View

struct AdvancedChartsView: View {
    @Binding var store: Store
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPeriod: ChartPeriod = .last3Months
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    periodSelector
                    
                    // Spending Trend
                    spendingTrendCard
                    
                    // Category Distribution
                    categoryPieCard
                    
                    // Income vs Expense
                    incomeExpenseCard
                    
                    // Monthly Comparison
                    monthlyComparisonCard
                }
                .padding()
            }
            .background(DS.Colors.bg.ignoresSafeArea())
            .navigationTitle("Charts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DS.Colors.subtext)
                    }
                }
            }
        }
    }
    
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ChartPeriod.allCases, id: \.self) { period in
                    Button {
                        Haptics.selection()
                        selectedPeriod = period
                    } label: {
                        Text(period.displayName)
                            .font(.system(size: 14, weight: selectedPeriod == period ? .semibold : .medium))
                            .foregroundStyle(selectedPeriod == period ? .black : DS.Colors.text)  // ← سیاه وقتی selected
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                selectedPeriod == period ?
                                Color.white :  // ← سفید وقتی selected
                                DS.Colors.surface2,
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(
                                        selectedPeriod == period ?
                                        Color.white.opacity(0.3) :
                                        DS.Colors.grid,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var spendingTrendCard: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20))
                        .foregroundStyle(DS.Colors.accent)
                    
                    Text("Spending Trend")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.Colors.text)
                    
                    Spacer()
                }
                
                SpendingTrendChart(store: store, period: selectedPeriod)
                    .frame(height: 200)
            }
        }
        .padding(.horizontal)
    }
    
    private var categoryPieCard: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DS.Colors.accent)
                    
                    Text("Category Breakdown")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.Colors.text)
                    
                    Spacer()
                }
                
                CategoryPieChart(store: store, period: selectedPeriod)
                    .frame(height: 250)
            }
        }
        .padding(.horizontal)
    }
    
    private var incomeExpenseCard: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DS.Colors.accent)
                    
                    Text("Income vs Expense")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.Colors.text)
                    
                    Spacer()
                }
                
                IncomeExpenseChart(store: store, period: selectedPeriod)
                    .frame(height: 200)
            }
        }
        .padding(.horizontal)
    }
    
    private var monthlyComparisonCard: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 20))
                        .foregroundStyle(DS.Colors.accent)
                    
                    Text("Monthly Comparison")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.Colors.text)
                    
                    Spacer()
                }
                
                MonthlyComparisonChart(store: store, period: selectedPeriod)
                    .frame(height: 220)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Chart Period

enum ChartPeriod: CaseIterable {
    case last3Months
    case last6Months
    case thisYear
    
    var displayName: String {
        switch self {
        case .last3Months: return "Last 3 Months"
        case .last6Months: return "Last 6 Months"
        case .thisYear: return "This Year"
        }
    }
    
    var monthsCount: Int {
        switch self {
        case .last3Months: return 3
        case .last6Months: return 6
        case .thisYear: return 12
        }
    }
}

// MARK: - Spending Trend Chart

struct SpendingTrendChart: View {
    let store: Store
    let period: ChartPeriod
    
    var data: [MonthData] {
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthData] = []
        
        for i in (0..<period.monthsCount).reversed() {
            guard let date = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            
            let spent = store.spent(for: date)
            let monthName = monthFormatter.string(from: date)
            
            result.append(MonthData(month: monthName, amount: spent, date: date))
        }
        
        return result
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    var body: some View {
        if data.isEmpty {
            Text("No data")
                .foregroundStyle(DS.Colors.subtext)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Chart(data) { item in
                LineMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", Double(item.amount) / 100.0)
                )
                .foregroundStyle(DS.Colors.accent)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", Double(item.amount) / 100.0)
                )
                .foregroundStyle(DS.Colors.accent.opacity(0.1))
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", Double(item.amount) / 100.0)
                )
                .foregroundStyle(DS.Colors.accent)
            }
            .chartYAxisLabel("€")
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 11))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 11))
                }
            }
        }
    }
}

struct MonthData: Identifiable {
    let id = UUID()
    let month: String
    let amount: Int
    let date: Date
}

// MARK: - Category Pie Chart

struct CategoryPieChart: View {
    let store: Store
    let period: ChartPeriod
    
    var data: [CategoryData] {
        let calendar = Calendar.current
        let now = Date()
        var categoryTotals: [Category: Int] = [:]
        
        for i in 0..<period.monthsCount {
            guard let date = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            
            let transactions = store.transactions.filter { tx in
                calendar.isDate(tx.date, equalTo: date, toGranularity: .month) && tx.type == .expense
            }
            
            for tx in transactions {
                categoryTotals[tx.category, default: 0] += tx.amount
            }
        }
        
        return categoryTotals
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map { CategoryData(category: $0.key, amount: $0.value) }
    }
    
    var body: some View {
        if data.isEmpty {
            Text("No data")
                .foregroundStyle(DS.Colors.subtext)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            VStack(spacing: 16) {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Amount", Double(item.amount) / 100.0),
                        innerRadius: .ratio(0.5),
                        angularInset: 2.0
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Category", item.category.title))
                }
                .frame(height: 180)
                
                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(data) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(categoryColor(for: item.category))
                                .frame(width: 8, height: 8)
                            
                            Text(item.category.title)
                                .font(.system(size: 11))
                                .foregroundStyle(DS.Colors.text)
                            
                            Spacer()
                            
                            Text(DS.Format.money(item.amount))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }
                }
            }
        }
    }
    
    private func categoryColor(for category: Category) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .red, .pink, .yellow, .cyan
        ]
        let index = Category.allCases.firstIndex(of: category) ?? 0
        return colors[index % colors.count]
    }
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: Category
    let amount: Int
}

// MARK: - Income vs Expense Chart

struct IncomeExpenseChart: View {
    let store: Store
    let period: ChartPeriod
    
    var data: [IncomeExpenseData] {
        let calendar = Calendar.current
        let now = Date()
        var result: [IncomeExpenseData] = []
        
        for i in (0..<period.monthsCount).reversed() {
            guard let date = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            
            let income = store.income(for: date)
            let expense = store.spent(for: date)
            let monthName = monthFormatter.string(from: date)
            
            result.append(IncomeExpenseData(month: monthName, income: income, expense: expense))
        }
        
        return result
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    var body: some View {
        if data.isEmpty {
            Text("No data")
                .foregroundStyle(DS.Colors.subtext)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Chart(data) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Income", Double(item.income) / 100.0)
                )
                .foregroundStyle(.green)
                .position(by: .value("Type", "Income"))
                
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Expense", Double(item.expense) / 100.0)
                )
                .foregroundStyle(.red.opacity(0.7))
                .position(by: .value("Type", "Expense"))
            }
            .chartYAxisLabel("€")
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 11))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 11))
                }
            }
        }
    }
}

struct IncomeExpenseData: Identifiable {
    let id = UUID()
    let month: String
    let income: Int
    let expense: Int
}

// MARK: - Monthly Comparison Chart

struct MonthlyComparisonChart: View {
    let store: Store
    let period: ChartPeriod
    
    var data: [MonthComparisonData] {
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthComparisonData] = []
        
        for i in (0..<period.monthsCount).reversed() {
            guard let date = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            
            let budget = store.budget(for: date)
            let spent = store.spent(for: date)
            let monthName = monthFormatter.string(from: date)
            
            result.append(MonthComparisonData(month: monthName, budget: budget, spent: spent))
        }
        
        return result
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    var body: some View {
        if data.isEmpty {
            Text("No data")
                .foregroundStyle(DS.Colors.subtext)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Chart(data) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Budget", Double(item.budget) / 100.0)
                )
                .foregroundStyle(.blue.opacity(0.3))
                .position(by: .value("Type", "Budget"))
                
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Spent", Double(item.spent) / 100.0)
                )
                .foregroundStyle(item.spent > item.budget ? Color.red : Color.green)
                .position(by: .value("Type", "Spent"))
            }
            .chartYAxisLabel("€")
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 11))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 11))
                }
            }
        }
    }
}

struct MonthComparisonData: Identifiable {
    let id = UUID()
    let month: String
    let budget: Int
    let spent: Int
}
