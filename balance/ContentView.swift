// ================================
// BalanceApp.swift
// ================================


// ================================
// ContentView.swift
// ================================

import SwiftUI
import Charts

// MARK: - Root

struct ContentView: View {
    @State private var store: Store = Store.load()
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                DashboardView(store: $store, goToBudget: { selectedTab = .budget })
                    .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.50percent") }
                    .tag(Tab.dashboard)

                TransactionsView(store: $store, goToBudget: { selectedTab = .budget })
                    .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle") }
                    .tag(Tab.transactions)

                BudgetView(store: $store)
                    .tabItem { Label("Budget", systemImage: "target") }
                    .tag(Tab.budget)

                InsightsView(store: $store, goToBudget: { selectedTab = .budget })
                    .tabItem { Label("Insights", systemImage: "sparkles") }
                    .tag(Tab.insights)
            }
            .onChange(of: store) { _, newValue in
                newValue.save()
            }
            .tint(DS.Colors.accent)
        }
    }
}

enum Tab: Hashable { case dashboard, transactions, budget, insights }

// MARK: - Dashboard

private struct DashboardView: View {
    @Binding var store: Store
    let goToBudget: () -> Void
    @State private var showAdd = false

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: store.selectedMonth)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header

                    if store.budgetTotal <= 0 {
                        SetupCard(goToBudget: goToBudget)
                    } else {
                        kpis
                        trendCard
                        categoryCard
                        advisorInsightsCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationTitle("Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if store.budgetTotal <= 0 {
                            goToBudget()
                        } else {
                            showAdd = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DS.Colors.text)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add transaction")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionSheet(store: $store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(monthTitle)
                            .font(DS.Typography.title)
                            .foregroundStyle(DS.Colors.text)
                        Text("Advisor: calm, precise, firm.")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                    }

                    Spacer()
                    MonthPicker(selectedMonth: $store.selectedMonth)
                }

                if store.budgetTotal <= 0 {
                    DS.StatusLine(
                        title: "Start from zero",
                        detail: "Set your monthly budget first. Analysis will start immediately.",
                        level: .watch
                    )
                } else {
                    let pressure = Analytics.budgetPressure(store: store)
                    DS.StatusLine(title: pressure.title, detail: pressure.detail, level: pressure.level)
                }
            }
        }
    }

    private var kpis: some View {
        let summary = Analytics.monthSummary(store: store)
        return HStack(spacing: 12) {
            KPI(title: "Spent", value: DS.Format.money(summary.totalSpent))
                .frame(maxWidth: .infinity)
            KPI(title: "Remaining", value: DS.Format.money(summary.remaining))
                .frame(maxWidth: .infinity)
            KPI(title: "Daily avg", value: DS.Format.money(summary.dailyAvg))
                .frame(maxWidth: .infinity)
        }
    }

    private var trendCard: some View {
        let points = Analytics.dailySpendPoints(store: store)
        return DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Daily spending trend")
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)

                if points.isEmpty {
                    Text("No trend data yet. Add a few transactions.")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.subtext)
                        .padding(.vertical, 6)
                } else {
                    Chart(points) { p in
                        LineMark(
                            x: .value("Day", p.day),
                            y: .value("Amount", p.amount)
                        )
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Day", p.day),
                            yStart: .value("Baseline", 0),
                            yEnd: .value("Amount", p.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(DS.Colors.text.opacity(0.18))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 5)) { _ in
                            AxisGridLine().foregroundStyle(DS.Colors.grid)
                            AxisValueLabel()
                                .foregroundStyle(DS.Colors.subtext)
                                .font(DS.Typography.caption)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine().foregroundStyle(DS.Colors.grid)
                            AxisValueLabel().foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    .frame(height: 170)
                }
            }
        }
    }

    private var categoryCard: some View {
        let breakdown = Analytics.categoryBreakdown(store: store)
        return DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Category breakdown")
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)

                if breakdown.isEmpty {
                    Text("Once you add transactions, category totals will appear here.")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.subtext)
                        .padding(.vertical, 6)
                } else {
                    Chart(breakdown) { row in
                        BarMark(
                            x: .value("Amount", row.total),
                            y: .value("Category", row.category.title)
                        )
                        .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine().foregroundStyle(DS.Colors.grid)
                            AxisValueLabel().foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel().foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    .frame(height: min(220, CGFloat(breakdown.count) * 28 + 40))

                    Divider().overlay(DS.Colors.grid)

                    VStack(spacing: 8) {
                        ForEach(breakdown.prefix(4)) { row in
                            HStack {
                                Text(row.category.title)
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.text)
                                Spacer()
                                Text(DS.Format.money(row.total))
                                    .font(DS.Typography.number)
                                    .foregroundStyle(DS.Colors.text)
                            }
                        }
                    }
                }
            }
        }
    }

    private var advisorInsightsCard: some View {
        let insights = Analytics.generateInsights(store: store).prefix(5)
        return DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Advisor insights")
                        .font(DS.Typography.section)
                        .foregroundStyle(DS.Colors.text)
                    Spacer()
                    Text("Honest, no blame")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                }

                if insights.isEmpty {
                    Text("Add a few everyday expenses for a more accurate assessment.")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.subtext)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(insights)) { insight in
                            InsightRow(insight: insight)
                        }
                    }
                }
            }
        }
    }
}

private struct SetupCard: View {
    let goToBudget: () -> Void

    var body: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Step 1: Set your monthly budget")
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)

                Text("Without a budget, the numbers have no target. Set a realistic budget—then we take control step by step.")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.subtext)

                Button {
                    goToBudget()
                } label: {
                    HStack {
                        Image(systemName: "target")
                        Text("Go to Budget")
                    }
                }
                .buttonStyle(DS.PrimaryButton())
            }
        }
    }
}

// MARK: - Transactions

private struct TransactionsView: View {
    @Binding var store: Store
    let goToBudget: () -> Void

    @State private var showAdd = false
    @State private var search = ""
    @State private var editingTxID: UUID? = nil

    private var filtered: [Transaction] {
        let monthTx = Analytics.monthTransactions(store: store)
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return monthTx }
        let s = search.lowercased()
        return monthTx.filter { $0.note.lowercased().contains(s) || $0.category.title.lowercased().contains(s) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()

                if store.budgetTotal <= 0 {
                    ScrollView {
                        VStack(spacing: 14) {
                            DS.Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Before you add transactions")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)

                                    Text("Set a monthly budget first so your spending can be evaluated.")
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.subtext)

                                    Button {
                                        goToBudget()
                                    } label: {
                                        HStack {
                                            Image(systemName: "target")
                                            Text("Set budget")
                                        }
                                    }
                                    .buttonStyle(DS.PrimaryButton())
                                }
                            }
                        }
                        .padding(16)
                    }
                } else {
                    List {
                        if filtered.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("No transactions this month.")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)
                                Text("Start with a simple expense. Consistency beats perfection.")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(DS.Colors.bg)
                        } else {
                            ForEach(Analytics.groupedByDay(filtered), id: \.day) { group in
                                Section {
                                    ForEach(group.items) { t in
                                        TransactionRow(t: t)
                                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                                Button {
                                                    editingTxID = t.id
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                .tint(.gray)
                                            }
                                    }
                                    .onDelete { idx in
                                        store.deleteTransactions(in: group.items, offsets: idx)
                                    }
                                } header: {
                                    Text(group.title)
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if store.budgetTotal > 0 {
                        EditButton().foregroundStyle(DS.Colors.subtext)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DS.Colors.text)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.budgetTotal <= 0)
                }
            }
            .searchable(text: $search, prompt: "Search category / note")
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionSheet(store: $store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: Binding<UUIDWrapper?>(
            get: { editingTxID.map { UUIDWrapper(id: $0) } },
            set: { editingTxID = $0?.id }
        )) { wrapper in
            EditTransactionSheet(store: $store, transactionID: wrapper.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Budget

private struct BudgetView: View {
    @Binding var store: Store

    @State private var editingTotal = ""
    @FocusState private var focus: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Set a monthly budget")
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)

                            Text("Keep it realistic. You can adjust it anytime.")
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.subtext)

                            HStack(spacing: 10) {
                                TextField("e.g. 30000000", text: $editingTotal)
                                    .keyboardType(.numberPad)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focus)
                                    .font(DS.Typography.number)
                                    .padding(11)
                                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(DS.Colors.grid, lineWidth: 1)
                                    )

                                Button(store.budgetTotal <= 0 ? "Start" : "Update") {
                                    let v = Int(editingTotal.filter(\.isNumber)) ?? 0
                                    store.budgetTotal = max(0, v)
                                    focus = false
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .frame(width: 140)
                            }

                            if store.budgetTotal <= 0 {
                                DS.StatusLine(
                                    title: "Analysis paused",
                                    detail: "Dashboard and insights unlock after you set a budget.",
                                    level: .watch
                                )
                            } else {
                                DS.StatusLine(
                                    title: "Budget set",
                                    detail: "You can now add transactions and get real analysis.",
                                    level: .ok
                                )
                            }
                        }
                    }

                    if store.budgetTotal > 0 {
                        DS.Card {
                            let summary = Analytics.monthSummary(store: store)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("This month")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                DS.Meter(
                                    title: "Budget used",
                                    value: summary.totalSpent,
                                    max: max(1, store.budgetTotal),
                                    hint: "\(DS.Format.percent(summary.spentRatio)) used"
                                )

                                Divider().overlay(DS.Colors.grid)

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Spent")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Text(DS.Format.money(summary.totalSpent))
                                            .font(DS.Typography.number)
                                            .foregroundStyle(DS.Colors.text)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Remaining")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Text(DS.Format.money(summary.remaining))
                                            .font(DS.Typography.number)
                                            .foregroundStyle(summary.remaining >= 0 ? DS.Colors.text : DS.Colors.danger)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationTitle("Budget")
            .onAppear {
                editingTotal = store.budgetTotal > 0 ? String(store.budgetTotal) : ""
            }
        }
    }
}

// MARK: - Insights

private struct InsightsView: View {
    @Binding var store: Store
    let goToBudget: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if store.budgetTotal <= 0 {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Insights are not ready")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                Text("Set your monthly budget first to unlock analysis.")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                Button { goToBudget() } label: {
                                    HStack {
                                        Image(systemName: "target")
                                        Text("Set budget")
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                            }
                        }
                    } else {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Analytical report")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                let proj = Analytics.projectedEndOfMonth(store: store)
                                DS.StatusLine(
                                    title: "End of month projection",
                                    detail: "If the current trend continues: \(DS.Format.money(proj.projectedTotal)) — \(proj.statusText) (\(DS.Format.money(proj.deltaAbs)))",
                                    level: proj.level
                                )

                                Text("Projection is based on average daily spending so far. New transactions refine the estimate.")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }

                        let insights = Analytics.generateInsights(store: store)
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Insights")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                if insights.isEmpty {
                                    Text("Not enough data yet. Add a few transactions.")
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.subtext)
                                        .padding(.vertical, 6)
                                } else {
                                    VStack(spacing: 10) {
                                        ForEach(insights) { insight in
                                            InsightRow(insight: insight)
                                        }
                                    }
                                }
                            }
                        }

                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Quick recommended actions")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                let actions = Analytics.quickActions(store: store)
                                if actions.isEmpty {
                                    Text("No urgent action needed. Stay consistent.")
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.subtext)
                                        .padding(.vertical, 6)
                                } else {
                                    VStack(spacing: 10) {
                                        ForEach(actions, id: \.self) { a in
                                            HStack(alignment: .top, spacing: 10) {
                                                Image(systemName: "checkmark.seal")
                                                    .foregroundStyle(DS.Colors.text)
                                                Text(a)
                                                    .font(DS.Typography.body)
                                                    .foregroundStyle(DS.Colors.text)
                                                Spacer(minLength: 0)
                                            }
                                            .padding(12)
                                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(DS.Colors.grid, lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationTitle("Insights")
        }
    }
}

// MARK: - Components

private struct KPI: View {
    let title: String
    let value: String

    var body: some View {
        DS.Card(padding: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
                Text(value)
                    .font(DS.Typography.number)
                    .foregroundStyle(DS.Colors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct TransactionRow: View {
    let t: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(t.category.tint.opacity(0.18))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: t.category.icon)
                        .foregroundStyle(t.category.tint)
                        .font(.system(size: 14, weight: .semibold))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(t.category.title)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.text)
                Text(t.note.isEmpty ? "—" : t.note)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
                    .lineLimit(1)
            }

            Spacer()

            Text(DS.Format.money(t.amount))
                .font(DS.Typography.number)
                .foregroundStyle(DS.Colors.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DS.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InsightRow: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(insight.level.color.opacity(0.18))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: insight.level.icon)
                        .foregroundStyle(insight.level.color)
                        .font(.system(size: 14, weight: .semibold))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(DS.Typography.body.weight(.semibold))
                    .foregroundStyle(DS.Colors.text)
                Text(insight.detail)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.subtext)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
}

private struct MonthPicker: View {
    @Binding var selectedMonth: Date

    var body: some View {
        HStack(spacing: 8) {
            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(DS.Colors.subtext)
                    .padding(8)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                selectedMonth = Date()
            } label: {
                Text("This month")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(DS.Colors.subtext)
                    .padding(8)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

// MARK: - Add Transaction Sheet

private struct AddTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var store: Store

    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var category: Category = .groceries

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Add expense")
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.Colors.text)
                    Spacer()
                    Button("Close") { dismiss() }
                        .foregroundStyle(DS.Colors.subtext)
                }

                DS.Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Amount")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)

                        TextField("e.g. 250000", text: $amountText)
                            .keyboardType(.numberPad)
                            .font(DS.Typography.number)
                            .padding(12)
                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(DS.Colors.grid, lineWidth: 1)
                            )

                        Divider().overlay(DS.Colors.grid)

                        Text("Category")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Category.allCases, id: \.self) { c in
                                    Button { category = c } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: c.icon)
                                            Text(c.title)
                                        }
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(category == c ? DS.Colors.text : DS.Colors.subtext)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 9)
                                        .background(
                                            (category == c ? c.tint.opacity(0.18) : DS.Colors.surface2),
                                            in: RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                .stroke(DS.Colors.grid, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }

                        Divider().overlay(DS.Colors.grid)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                DatePicker("", selection: $date, displayedComponents: [.date])
                                    .labelsHidden()
                            }
                            Spacer()
                        }

                        Divider().overlay(DS.Colors.grid)

                        Text("Note (optional)")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)

                        TextField("e.g. groceries", text: $note)
                            .font(DS.Typography.body)
                            .padding(12)
                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(DS.Colors.grid, lineWidth: 1)
                            )
                    }
                }

                Button {
                    let raw = amountText.filter(\.isNumber)
                    let amount = Int(raw) ?? 0
                    guard amount > 0 else { return }
                    store.add(Transaction(amount: amount, date: date, category: category, note: note))
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save")
                    }
                }
                .buttonStyle(DS.PrimaryButton())
                .disabled((Int(amountText.filter(\.isNumber)) ?? 0) <= 0)

                Text("Advisor note: accurate tracking is the fastest path to control.")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)

                Spacer()
            }
            .padding(16)
        }
    }
}


private struct EditTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var store: Store
    let transactionID: UUID

    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var category: Category = .groceries

    private var index: Int? {
        store.transactions.firstIndex { $0.id == transactionID }
    }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Edit expense")
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.Colors.text)
                    Spacer()
                    Button("Close") { dismiss() }
                        .foregroundStyle(DS.Colors.subtext)
                        .buttonStyle(.plain)
                }

                DS.Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Amount")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)

                        TextField("e.g. 250", text: $amountText)
                            .keyboardType(.numberPad)
                            .font(DS.Typography.number)
                            .padding(12)
                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(DS.Colors.grid, lineWidth: 1)
                            )

                        Divider().overlay(DS.Colors.grid)

                        Text("Category")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Category.allCases, id: \.self) { c in
                                    Button { category = c } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: c.icon)
                                            Text(c.title)
                                        }
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(category == c ? DS.Colors.text : DS.Colors.subtext)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 9)
                                        .background(
                                            (category == c ? c.tint.opacity(0.18) : DS.Colors.surface2),
                                            in: RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                .stroke(DS.Colors.grid, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Divider().overlay(DS.Colors.grid)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                DatePicker("", selection: $date, displayedComponents: [.date])
                                    .labelsHidden()
                            }
                            Spacer()
                        }

                        Divider().overlay(DS.Colors.grid)

                        Text("Note (optional)")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)

                        TextField("e.g. groceries", text: $note)
                            .font(DS.Typography.body)
                            .padding(12)
                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(DS.Colors.grid, lineWidth: 1)
                            )
                    }
                }

                Button {
                    guard let idx = index else { return }
                    let raw = amountText.filter(\.isNumber)
                    let amount = Int(raw) ?? 0
                    guard amount > 0 else { return }

                    let existingID = store.transactions[idx].id
                    store.transactions[idx] = Transaction(
                        id: existingID,
                        amount: amount,
                        date: date,
                        category: category,
                        note: note
                    )
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save changes")
                    }
                }
                .buttonStyle(DS.PrimaryButton())
                .disabled((Int(amountText.filter(\.isNumber)) ?? 0) <= 0 || index == nil)

                Spacer()
            }
            .padding(16)
        }
        .onAppear {
            guard let idx = index else { return }
            let t = store.transactions[idx]
            amountText = String(t.amount)
            note = t.note
            date = t.date
            category = t.category
        }
    }
}


// MARK: - Design System

private enum DS {
    enum Colors {
        // Core dark palette (NO blues)
        static let bg = Color.black
        static let surface  = Color(hex: 0x0E0E10)   // near-black
        static let surface2 = Color(hex: 0x141417)   // slightly lifted

        static let text = Color.white
        static let subtext = Color.white.opacity(0.70)
        static let grid = Color.white.opacity(0.10)

        // Accent stays neutral (white). Status uses only green/red.
        static let accent = Color.white
        static let buttonFill = Color.black

        static let positive = Color(hex: 0x2ED573)   // green
        static let warning  = Color.white            // neutral attention (no yellow/blue)
        static let danger   = Color(hex: 0xFF3B30)   // red
    }

    enum Typography {
        static let title = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let section = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 14, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let number = Font.system(size: 16, weight: .semibold, design: .monospaced)
    }

    struct Card<Content: View>: View {
        var padding: CGFloat = 14
        @ViewBuilder var content: Content
        var body: some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(padding)
                .background(Colors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Colors.grid, lineWidth: 1)
                )
        }
    }

    struct PrimaryButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Color.black)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                )
                .opacity(configuration.isPressed ? 0.85 : 1.0)
        }
    }

    struct StatusLine: View {
        let title: String
        let detail: String
        let level: Level

        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(level.color.opacity(0.18))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: level.icon)
                            .foregroundStyle(level.color)
                            .font(.system(size: 12, weight: .semibold))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Typography.body.weight(.semibold))
                        .foregroundStyle(Colors.text)
                    Text(detail)
                        .font(Typography.caption)
                        .foregroundStyle(Colors.subtext)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Colors.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Colors.grid, lineWidth: 1)
            )
        }
    }

    struct Meter: View {
        let title: String
        let value: Int
        let max: Int
        let hint: String

        private var ratio: Double { min(1, Double(value) / Double(max)) }
        private var level: Level {
            switch ratio {
            case ..<0.75: return .ok
            case ..<0.95: return .watch
            default: return .risk
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(Typography.caption)
                        .foregroundStyle(Colors.subtext)
                    Spacer()
                    Text(hint)
                        .font(Typography.caption)
                        .foregroundStyle(Colors.subtext)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Colors.surface2)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(level.color)
                            .frame(width: geo.size.width * ratio)
                            .opacity(0.85)
                    }
                }
                .frame(height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Colors.grid, lineWidth: 1)
                )
            }
        }
    }

    enum Format {
        static func money(_ v: Int) -> String {
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.locale = Locale(identifier: "en_US_POSIX")
            nf.currencyCode = "EUR"
            nf.currencySymbol = "€"
            return nf.string(from: NSNumber(value: v)) ?? "€\(v)"
        }

        static func percent(_ x: Double) -> String {
            let p = Int((x * 100).rounded())
            return "\(p)%"
        }
    }
}

// MARK: - Domain

struct Transaction: Identifiable, Hashable, Codable {
    let id: UUID
    var amount: Int
    var date: Date
    var category: Category
    var note: String

    init(id: UUID = UUID(), amount: Int, date: Date, category: Category, note: String) {
        self.id = id
        self.amount = amount
        self.date = date
        self.category = category
        self.note = note
    }
}

enum Category: String, CaseIterable, Hashable, Codable {
    case groceries, rent, bills, transport, health, education, dining, shopping, entertainment, other

    var title: String {
        switch self {
        case .groceries: return "Groceries"
        case .rent: return "Rent"
        case .bills: return "Bills"
        case .transport: return "Transport"
        case .health: return "Health"
        case .education: return "Education"
        case .dining: return "Dining"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .groceries: return "basket"
        case .rent: return "house"
        case .bills: return "doc.text"
        case .transport: return "car"
        case .health: return "cross.case"
        case .education: return "book"
        case .dining: return "fork.knife"
        case .shopping: return "bag"
        case .entertainment: return "gamecontroller"
        case .other: return "square.grid.2x2"
        }
    }

    var tint: Color {
        switch self {
        case .groceries:
            return Color.green // green
        case .rent:
            return Color.yellow // white
        case .bills:
            return Color.orange // cool gray
        case .transport:
            return Color.blue // steel blue (muted)
        case .health:
            return Color(hex: 0x68DEA9) // teal green
        case .education:
            return Color(hex: 0x576574) // graphite
        case .dining:
            return Color(hex: 0xFF6B6B) // red
        case .shopping:
            return Color(hex: 0xE84393) // dark pink / magenta
        case .entertainment:
            return Color.purple // purple
        case .other:
            return Color(hex: 0x8395A7) // neutral gray‑blue
        }
    }
}

// MARK: - Store

struct Store: Hashable, Codable {
    var selectedMonth: Date = Date()
    var budgetsByMonth: [String: Int] = [:]
    var transactions: [Transaction] = []

    private static func monthKey(_ date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }

    /// Budget for the currently selected month.
    var budgetTotal: Int {
        get { budgetsByMonth[Self.monthKey(selectedMonth)] ?? 0 }
        set { budgetsByMonth[Self.monthKey(selectedMonth)] = max(0, newValue) }
    }

    func budget(for month: Date) -> Int {
        budgetsByMonth[Self.monthKey(month)] ?? 0
    }

    mutating func setBudget(_ value: Int, for month: Date) {
        budgetsByMonth[Self.monthKey(month)] = max(0, value)
    }

    mutating func add(_ t: Transaction) { transactions.append(t) }

    mutating func deleteTransactions(in items: [Transaction], offsets: IndexSet) {
        let toDelete = offsets.map { items[$0].id }
        transactions.removeAll { toDelete.contains($0.id) }
    }


    // MARK: - Persistence

    private static let storageKey = "balance.store.v1"

    static func load() -> Store {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey)
        else {
            return Store()
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Store.self, from: data)
        } catch {
            // If decoding fails (schema change, corrupted data), start fresh.
            return Store()
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            // Ignore save failures silently for now.
        }
    }
}

// MARK: - Analytics

struct Insight: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let level: Level
}

enum Level: Hashable {
    case ok, watch, risk

    var icon: String {
        switch self {
        case .ok: return "checkmark"
        case .watch: return "exclamationmark"
        case .risk: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .ok: return DS.Colors.positive
        case .watch: return DS.Colors.warning
        case .risk: return DS.Colors.danger
        }
    }
}

enum Analytics {

    struct MonthSummary {
        let totalSpent: Int
        let remaining: Int
        let dailyAvg: Int
        let spentRatio: Double
    }

    struct Pressure {
        let title: String
        let detail: String
        let level: Level
    }

    struct Projection {
        let projectedTotal: Int
        let deltaAbs: Int
        let statusText: String
        let level: Level
    }

    struct DayPoint: Identifiable {
        let id = UUID()
        let day: Int
        let amount: Int
    }

    struct CategoryRow: Identifiable {
        let id = UUID()
        let category: Category
        let total: Int
    }

    struct DayGroup {
        let day: Date
        let title: String
        let items: [Transaction]
    }

    static func monthTransactions(store: Store) -> [Transaction] {
        let cal = Calendar.current
        return store.transactions
            .filter { cal.isDate($0.date, equalTo: store.selectedMonth, toGranularity: .month) }
            .sorted { $0.date > $1.date }
    }

    static func monthSummary(store: Store) -> MonthSummary {
        let tx = monthTransactions(store: store)
        let total = tx.reduce(0) { $0 + $1.amount }
        let remaining = store.budgetTotal - total

        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: store.selectedMonth) ?? 1..<31
        let daysInMonth = range.count
        let dayNow = cal.component(.day, from: Date())
        let isCurrentMonth = cal.isDate(Date(), equalTo: store.selectedMonth, toGranularity: .month)
        let divisor = max(1, isCurrentMonth ? min(dayNow, daysInMonth) : daysInMonth)
        let dailyAvg = total / divisor

        let ratio = store.budgetTotal > 0 ? Double(total) / Double(store.budgetTotal) : 0
        return .init(totalSpent: total, remaining: remaining, dailyAvg: dailyAvg, spentRatio: ratio)
    }

    static func budgetPressure(store: Store) -> Pressure {
        let s = monthSummary(store: store)
        if s.spentRatio < 0.75 {
            return .init(title: "Stable", detail: "Spending is under control. Keep the pattern.", level: .ok)
        } else if s.spentRatio < 0.95 {
            return .init(title: "Needs attention", detail: "You’re approaching the budget limit. Review discretionary spending.", level: .watch)
        } else {
            return .init(title: "Budget pressure", detail: "Spending is very high. Reduce non‑essential costs.", level: .risk)
        }
    }

    static func projectedEndOfMonth(store: Store) -> Projection {
        let summary = monthSummary(store: store)
        guard store.budgetTotal > 0 else {
            return Projection(projectedTotal: summary.totalSpent, deltaAbs: 0, statusText: "Budget not set", level: .watch)
        }

        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: store.selectedMonth) ?? 1..<31
        let daysInMonth = range.count

        let isCurrentMonth = calendar.isDate(Date(), equalTo: store.selectedMonth, toGranularity: .month)
        let dayNow = calendar.component(.day, from: Date())
        let elapsed = max(1, isCurrentMonth ? min(dayNow, daysInMonth) : daysInMonth)

        let dailyAvg = Double(summary.totalSpent) / Double(elapsed)
        let projected = Int((dailyAvg * Double(daysInMonth)).rounded())

        let delta = projected - store.budgetTotal

        if delta <= 0 {
            return Projection(projectedTotal: projected, deltaAbs: abs(delta), statusText: "Below monthly budget", level: .ok)
        } else if delta < store.budgetTotal / 10 {
            return Projection(projectedTotal: projected, deltaAbs: delta, statusText: "Close to budget limit", level: .watch)
        } else {
            return Projection(projectedTotal: projected, deltaAbs: delta, statusText: "Likely to exceed budget", level: .risk)
        }
    }

    static func dailySpendPoints(store: Store) -> [DayPoint] {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return [] }

        let cal = Calendar.current
        var byDay: [Int: Int] = [:]
        for t in tx {
            let d = cal.component(.day, from: t.date)
            byDay[d, default: 0] += t.amount
        }
        return byDay.keys.sorted().map { DayPoint(day: $0, amount: byDay[$0] ?? 0) }
    }

    static func categoryBreakdown(store: Store) -> [CategoryRow] {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return [] }

        var map: [Category: Int] = [:]
        for t in tx { map[t.category, default: 0] += t.amount }

        return map
            .map { CategoryRow(category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    static func groupedByDay(_ tx: [Transaction]) -> [DayGroup] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: tx) { cal.startOfDay(for: $0.date) }

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "EEEE, MMM d"

        return groups
            .map { (day, items) in
                DayGroup(day: day, title: fmt.string(from: day), items: items.sorted { $0.date > $1.date })
            }
            .sorted { $0.day > $1.day }
    }

    static func generateInsights(store: Store) -> [Insight] {
        let tx = monthTransactions(store: store)
        guard tx.count >= 5 else { return [] }

        var out: [Insight] = []

        let proj = projectedEndOfMonth(store: store)
        if proj.level != .ok {
            let title = proj.level == .risk ? "This trend will pressure your budget" : "Approaching the limit"
            let detail = proj.level == .risk
                ? "End-of-month projection is above budget. Prioritize cutting discretionary costs."
                : "To stay in control, trim one discretionary category slightly."
            out.append(.init(title: title, detail: detail, level: proj.level))
        } else {
            out.append(.init(title: "Good control", detail: "Current trend aligns with your budget. Keep it steady.", level: .ok))
        }

        let breakdown = categoryBreakdown(store: store)
        if let top = breakdown.first {
            let total = breakdown.reduce(0) { $0 + $1.total }
            let share = total > 0 ? Double(top.total) / Double(total) : 0
            if share > 0.35 {
                out.append(.init(
                    title: "Spending concentrated in “\(top.category.title)”",
                    detail: "This category is \(DS.Format.percent(share)) of monthly spending. If reducible, start here.",
                    level: .watch
                ))
            }
        }

        let smallThreshold = max(80_000, store.budgetTotal / 500)
        let smalls = tx.filter { $0.amount <= smallThreshold }
        if smalls.count >= 8 {
            let sum = smalls.reduce(0) { $0 + $1.amount }
            out.append(.init(
                title: "Small expenses are adding up",
                detail: "You have \(smalls.count) small transactions totaling \(DS.Format.money(sum)). Set a daily cap for small spending.",
                level: .watch
            ))
        }

        let dining = tx.filter { $0.category == .dining }.reduce(0) { $0 + $1.amount }
        let ent = tx.filter { $0.category == .entertainment }.reduce(0) { $0 + $1.amount }
        let total = tx.reduce(0) { $0 + $1.amount }
        if total > 0 {
            let opt = dining + ent
            let share = Double(opt) / Double(total)
            if share > 0.22 {
                out.append(.init(
                    title: "Discretionary costs can be reduced",
                    detail: "Dining + Entertainment is \(DS.Format.percent(share)) of spending. A 10% cut noticeably reduces pressure.",
                    level: .watch
                ))
            }
        }

        let s = monthSummary(store: store)
        if s.remaining < 0 {
            out.append(.init(
                title: "Over budget",
                detail: "You’re above the monthly budget. Firm move: pause non‑essential spending until month end.",
                level: .risk
            ))
        }

        return out.sorted { rank($0.level) > rank($1.level) }
    }

    static func quickActions(store: Store) -> [String] {
        let tx = monthTransactions(store: store)
        guard tx.count >= 5 else { return [] }

        var actions: [String] = []
        let proj = projectedEndOfMonth(store: store)

        if proj.level == .risk {
            actions.append("Set a daily spending cap for the next 7 days.")
            actions.append("Temporarily limit one discretionary category (Dining / Entertainment / Shopping).")
        }

        if let top = categoryBreakdown(store: store).first {
            actions.append("Set a weekly cap for “\(top.category.title)”.")
        }

        return Array(actions.prefix(3))
    }

    private static func rank(_ l: Level) -> Int { l == .risk ? 3 : (l == .watch ? 2 : 1) }
}


private struct UUIDWrapper: Identifiable {
    let id: UUID
}

// MARK: - Helpers

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
