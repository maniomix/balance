import SwiftUI
import Charts
import UIKit
import UserNotifications
import ZIPFoundation
import UniformTypeIdentifiers
import CryptoKit

// MARK: - Root

struct ContentView: View {
    @State private var store: Store = Store.load()
    @State private var selectedTab: Tab = .dashboard

    // Debounced persistence
    @State private var saveWorkItem: DispatchWorkItem? = nil

    // Debounced smart-rule evaluation to prevent repeated scheduling/firing
    @State private var notifEvalWorkItem: DispatchWorkItem? = nil
    @State private var didSyncNotifications: Bool = false

    @AppStorage("notifications.enabled")
    private var notificationsEnabled: Bool = false

    private let saveDebounceSeconds: TimeInterval = 0.6
    private let notifEvalDebounceSeconds: TimeInterval = 0.9

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
            .onAppear {
                // اجازه بده نوتیف‌ها داخل برنامه هم بنر بشن
                UNUserNotificationCenter.current().delegate =
                    NotificationCenterDelegate.shared

                // اگر قبلاً نوتیف روشن بوده، ruleها فعال باشن
                // (فقط یکبار در هر اجرای برنامه سینک کن تا نوتیف تکراری ساخته نشه)
                if notificationsEnabled && !didSyncNotifications {
                    didSyncNotifications = true
                    Task {
                        await Notifications.syncAll(store: store)
                    }
                }
            }
            .onChange(of: store) { _, newStore in
                // هر تغییری در store (اضافه/ادیت/حذف ترنزکشن)
                // ruleها رو با debounce بررسی کن تا نوتیف تکراری ساخته/فایر نشه
                guard notificationsEnabled else { return }

                notifEvalWorkItem?.cancel()
                let item = DispatchWorkItem {
                    Task {
                        await Notifications.evaluateSmartRules(store: newStore)
                    }
                }
                notifEvalWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + notifEvalDebounceSeconds, execute: item)
            }
            .onChange(of: store) { _, newValue in
                // Debounce saves to avoid writing on every keystroke / UI state change.
                saveWorkItem?.cancel()
                let item = DispatchWorkItem {
                    newValue.save()
                }
                saveWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceSeconds, execute: item)
            }
            .tint(DS.Colors.accent)
        }
    }
}

enum Tab: Hashable { case dashboard, transactions, budget, insights }


// ذخیره تاریخچه ایمپورت (hash دیتاست)
enum ImportHistory {
    private static let key = "imports.hashes.v1"

    static func load() -> Set<String> {
        let arr = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(arr)
    }

    static func contains(_ hash: String) -> Bool {
        load().contains(hash)
    }

    static func append(_ hash: String) {
        var set = load()
        set.insert(hash)
        UserDefaults.standard.set(Array(set), forKey: key)
    }
}

enum ImportDeduper {
    static func signature(for t: Transaction) -> String {
        let note = t.note.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate] // yyyy-MM-dd
        let day = iso.string(from: t.date)

        // اگر Category RawRepresentable هست، rawValue بهتره؛ وگرنه description
        let cat = String(describing: t.category)

        // amount فرض: cents (Int)
        return "\(day)|\(t.amount)|\(cat)|\(note)"
    }

    static func datasetHash(transactions: [Transaction]) -> String {
        let lines = transactions.map(signature(for:)).sorted()
        let joined = lines.joined(separator: "\n")
        let digest = SHA256.hash(data: Data(joined.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Haptics
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Dashboard

private struct DashboardView: View {
    @Binding var store: Store
    let goToBudget: () -> Void
    @State private var showAdd = false
    @State private var trendSelectedDay: Int? = nil

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return fmt.string(from: store.selectedMonth)
    }

    private var todayDay: String {
        let cal = Calendar.current
        let day = cal.component(.day, from: Date())
        return "\(day)"
    }

    private func dateString(forDay day: Int) -> String {
        var cal = Calendar.current
        cal.locale = .current
        var comps = cal.dateComponents([.year, .month], from: store.selectedMonth)
        comps.day = day
        let d = cal.date(from: comps) ?? store.selectedMonth

        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        return fmt.string(from: d)
    }
    
    @State private var showDeleteMonthConfirm = false
    @State private var showTrashAlert = false
    @State private var trashAlertText = ""

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
                // 🔴 دکمه حذف کل ماه (سمت چپ)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // If there is nothing to delete for the selected month, show a message instead of asking again.
                        let hasTx = !Analytics.monthTransactions(store: store).isEmpty
                        let hasBudget = store.budgetTotal > 0
                        let hasCaps = store.totalCategoryBudgets() > 0
                        let hasAnything = hasTx || hasBudget || hasCaps

                        if hasAnything {
                            showDeleteMonthConfirm = true
                        } else {
                            trashAlertText = "This month has already been cleared. There is nothing left to delete."
                            showTrashAlert = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.Colors.danger)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete this month")
                }

                // ➕ دکمه اضافه کردن (سمت راست – همونی که داشتی)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.medium()
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
        .alert("Delete this month's data?", isPresented: $showDeleteMonthConfirm) {
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    store.clearMonthData(for: store.selectedMonth)
                }
                store.save()
                Haptics.success()
                trashAlertText = "This month's data has been successfully deleted"
                showTrashAlert = true
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All transactions, the monthly budget, and category limits for this month will be permanently deleted.")
        }
        .alert("Trash", isPresented: $showTrashAlert) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(trashAlertText)
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
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(todayDay)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(DS.Colors.text.opacity(1))

                            Text(monthTitle)
                                .font(DS.Typography.title)
                                .foregroundStyle(DS.Colors.text)
                        }
                        Text("Data For this Month")
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
                    if let capPressure = Analytics.categoryCapPressure(store: store) {
                        DS.StatusLine(title: capPressure.title, detail: capPressure.detail, level: capPressure.level)
                    } else {
                        let pressure = Analytics.budgetPressure(store: store)
                        DS.StatusLine(title: pressure.title, detail: pressure.detail, level: pressure.level)
                    }
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
                        .foregroundStyle(DS.Colors.text)

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
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisGridLine().foregroundStyle(DS.Colors.grid)
                            AxisTick()
                            AxisValueLabel {
                                if let vInt = value.as(Int.self) {
                                    Text(DS.Format.money(vInt))
                                        .foregroundStyle(DS.Colors.subtext)
                                        .font(DS.Typography.caption)
                                } else if let v = value.as(Double.self) {
                                    Text(DS.Format.money(Int(v.rounded())))
                                        .foregroundStyle(DS.Colors.subtext)
                                        .font(DS.Typography.caption)
                                }
                            }
                        }
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            if let plotAnchor = proxy.plotFrame {
                                let frame = geo[plotAnchor]

                                ZStack(alignment: .topLeading) {
                                    // Gesture capture
                                    Rectangle()
                                        .fill(.clear)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    let loc = value.location
                                                    guard frame.contains(loc) else { return }
                                                    let xInPlot = loc.x - frame.minX

                                                    var newDay: Int?
                                                    if let d: Int = proxy.value(atX: xInPlot) {
                                                        newDay = d
                                                    } else if let d: Double = proxy.value(atX: xInPlot) {
                                                        newDay = Int(d.rounded())
                                                    }

                                                    if let newDay, newDay != trendSelectedDay {
                                                        trendSelectedDay = newDay
                                                        Haptics.selection()
                                                    }
                                                }
                                                .onEnded { _ in
                                                    trendSelectedDay = nil
                                                }
                                        )

                                    if let selDay = trendSelectedDay,
                                       let p = points.min(by: { abs($0.day - selDay) < abs($1.day - selDay) }),
                                       let xPos = proxy.position(forX: p.day),
                                       let yPos = proxy.position(forY: p.amount) {

                                        let x = frame.minX + xPos
                                        let y = frame.minY + yPos

                                        // Vertical rule line
                                        Path { path in
                                            path.move(to: CGPoint(x: x, y: frame.minY))
                                            path.addLine(to: CGPoint(x: x, y: frame.maxY))
                                        }
                                        .stroke(DS.Colors.text.opacity(0.35), lineWidth: 1)

                                        // Highlight point (outer glow + inner dot)
                                        Circle()
                                            .fill(DS.Colors.text.opacity(0.18))
                                            .frame(width: 18, height: 18)
                                            .position(x: x, y: y)

                                        Circle()
                                            .fill(DS.Colors.text)
                                            .frame(width: 7, height: 7)
                                            .position(x: x, y: y)

                                        // Tooltip
                                        let tooltipW: CGFloat = 170
                                        let pad: CGFloat = 10
                                        let tx = min(max(x + 14, pad + tooltipW / 2), geo.size.width - pad - tooltipW / 2)
                                        let ty = max(frame.minY + 12, y - 44)

                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack(spacing: 8) {
                                                Text("Spent")
                                                    .font(DS.Typography.caption.weight(.semibold))
                                                    .foregroundStyle(DS.Colors.text)
                                                Spacer()
                                                Text(DS.Format.money(p.amount))
                                                    .font(DS.Typography.caption.weight(.semibold))
                                                    .foregroundStyle(DS.Colors.text)
                                            }

                                            Text(dateString(forDay: p.day))
                                                .font(DS.Typography.caption)
                                                .foregroundStyle(DS.Colors.subtext)
                                        }
                                        .padding(10)
                                        .frame(width: tooltipW, alignment: .leading)
                                        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(DS.Colors.grid, lineWidth: 1)
                                        )
                                        .position(x: tx, y: ty)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 170)
                }
            }
        }
    }

    private var categoryCard: some View {
        let breakdown = Analytics.categoryBreakdown(store: store)
        let monthTx = Analytics.monthTransactions(store: store)

        // Build a spent map so we can show category caps even if a category isn't in top breakdown.
        var spentByCategory: [Category: Int] = [:]
        for t in monthTx { spentByCategory[t.category, default: 0] += t.amount }

        // Rows to show under the chart:
        // 1) Top categories by spend (up to 6)
        // 2) Any category that has a cap set (even if spend is zero) so the cap UI always appears
        let topCats: [Category] = breakdown.prefix(6).map { $0.category }
        let cappedCats: [Category] = Category.allCases.filter { store.categoryBudget(for: $0) > 0 }
        let orderedCats: [Category] = Array(NSOrderedSet(array: topCats + cappedCats))
            .compactMap { $0 as? Category }

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

                    VStack(spacing: 10) {
                        ForEach(orderedCats, id: \.self) { c in
                            let spent = spentByCategory[c] ?? 0
                            let cap = store.categoryBudget(for: c)

                            if cap > 0 {
                                CategoryCapRow(category: c, spent: spent, cap: cap)
                            } else if spent > 0 {
                                CategoryTotalRow(category: c, spent: spent)
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
    @State private var showFilters = false
    @State private var selectedCategories: Set<Category> = Set(Category.allCases)
    @State private var useDateRange = false
    @State private var dateFrom = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var dateTo = Date()
    @State private var minAmountText = ""
    @State private var maxAmountText = ""
    @State private var editingTxID: UUID? = nil
    @State private var showImport = false

    // --- Multi-select state for Transactions screen ---
    @State private var isSelecting = false
    @State private var selectedTxIDs: Set<UUID> = []
    
    // --- Undo delete ---
    @State private var pendingUndo: [Transaction] = []
    @State private var showUndoBar: Bool = false
    @State private var undoWorkItem: DispatchWorkItem? = nil
    private let undoDelay: TimeInterval = 4.0
    private let undoAnim: Animation = .spring(response: 0.45, dampingFraction: 0.90)
    
    private func scheduleUndoCommit() {
        undoWorkItem?.cancel()

        withAnimation(undoAnim) {
            showUndoBar = true
        }

        let item = DispatchWorkItem {
            withAnimation(undoAnim) {
                pendingUndo.removeAll()
                showUndoBar = false
            }
        }

        undoWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + undoDelay, execute: item)
    }

    private func undoDelete() {
        undoWorkItem?.cancel()
        withAnimation(uiAnim) {
            store.transactions.append(contentsOf: pendingUndo)
        }
        pendingUndo.removeAll()
        showUndoBar = false
    }

    private let uiAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.0)

    private var filtered: [Transaction] {
        let monthTx = Analytics.monthTransactions(store: store)

        // Text search
        var out = monthTx
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let s = trimmed.lowercased()
            out = out.filter { $0.note.lowercased().contains(s) || $0.category.title.lowercased().contains(s) }
        }

        // Category filter
        if selectedCategories.count != Category.allCases.count {
            out = out.filter { selectedCategories.contains($0.category) }
        }

        // Amount range filter (values are stored in euro cents)
        let minCents = DS.Format.cents(from: minAmountText)
        let maxCents = DS.Format.cents(from: maxAmountText)
        if minCents > 0 {
            out = out.filter { $0.amount >= minCents }
        }
        if maxCents > 0 {
            out = out.filter { $0.amount <= maxCents }
        }

        // Date range filter
        if useDateRange {
            let cal = Calendar.current
            let start = cal.startOfDay(for: dateFrom)
            // Include the entire end day
            let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: dateTo)) ?? dateTo
            out = out.filter { $0.date >= start && $0.date < end }
        }

        return out
    }

    private var activeFilterCount: Int {
        var n = 0
        if selectedCategories.count != Category.allCases.count { n += 1 }
        if useDateRange { n += 1 }
        if DS.Format.cents(from: minAmountText) > 0 || DS.Format.cents(from: maxAmountText) > 0 { n += 1 }
        return n
    }

    // --- Add state for pending delete confirmation (anchored to row)
    @State private var pendingDeleteID: UUID? = nil

    // Helper binding for single row delete confirmation dialog
    private var isRowDeleteDialogPresented: Binding<Bool> {
        Binding(
            get: { pendingDeleteID != nil },
            set: { presenting in
                if !presenting { pendingDeleteID = nil }
            }
        )
    }

    // Helper binding for bulk delete confirmation dialog
    private var isBulkDeleteDialogPresented: Binding<Bool> {
        Binding(
            get: { showBulkDeletePopover && isSelecting && !selectedTxIDs.isEmpty },
            set: { presenting in
                if !presenting { showBulkDeletePopover = false }
            }
        )
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
                    // --- Transactions List with Multi-Select ---
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
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        } else {
                            ForEach(Analytics.groupedByDay(filtered), id: \.day) { group in
                                Section {
                                    ForEach(group.items) { t in
                                        HStack(spacing: 10) {
                                            if isSelecting {
                                                Image(systemName: selectedTxIDs.contains(t.id) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundStyle(selectedTxIDs.contains(t.id) ? DS.Colors.positive : DS.Colors.subtext)
                                                    .font(.system(size: 18))
                                                    .onTapGesture {
                                                        if selectedTxIDs.contains(t.id) {
                                                            selectedTxIDs.remove(t.id)
                                                        } else {
                                                            selectedTxIDs.insert(t.id)
                                                        }
                                                        Haptics.selection()
                                                    }
                                            }

                                            TransactionRow(t: t)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    guard isSelecting else { return }
                                                    if selectedTxIDs.contains(t.id) {
                                                        selectedTxIDs.remove(t.id)
                                                    } else {
                                                        selectedTxIDs.insert(t.id)
                                                    }
                                                    Haptics.selection()
                                                }
                                        }
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                                        .contextMenu {
                                            Button {
                                                withAnimation(uiAnim) {
                                                    editingTxID = t.id
                                                }
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }

                                            Button(role: .destructive) {
                                                pendingDeleteID = t.id
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
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
                    .animation(uiAnim, value: filtered)
                    .animation(uiAnim, value: activeFilterCount)
                    .animation(uiAnim, value: store.transactions)
                    .confirmationDialog(
                        "Delete transaction?",
                        isPresented: isRowDeleteDialogPresented,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            // Capture id first, then dismiss dialog BEFORE mutating list.
                            let id = pendingDeleteID
                            pendingDeleteID = nil

                            guard let id,
                                  let tx = store.transactions.first(where: { $0.id == id }) else { return }

                            // remove now + show undo
                            pendingUndo = [tx]
                            withAnimation(uiAnim) {
                                store.transactions.removeAll { $0.id == id }
                            }
                            scheduleUndoCommit()
                        }
                        Button("Cancel", role: .cancel) {
                            pendingDeleteID = nil
                        }
                    } message: {
                        Text("This action can’t be undone.")
                    }
                    .safeAreaInset(edge: .bottom) {
                        if showUndoBar {
                            HStack {
                                Text("\(pendingUndo.count) transaction deleted")
                                    .foregroundStyle(DS.Colors.text)

                                Spacer()

                                Button("Undo") {
                                    undoDelete()
                                }
                                .foregroundStyle(DS.Colors.positive)
                            }
                            .padding()
                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(DS.Colors.grid, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            .scaleEffect(0.98)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
            
            .toolbar { toolbarItems }
            .searchable(text: $search, prompt: "Search category / note")
            .confirmationDialog(
                "Delete \(selectedTxIDs.count) transactions?",
                isPresented: isBulkDeleteDialogPresented,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    // Capture selection first
                    let ids = selectedTxIDs

                    // stash for undo
                    pendingUndo = store.transactions.filter { ids.contains($0.id) }

                    // Dismiss dialog + exit selecting mode BEFORE mutating the list
                    showBulkDeletePopover = false
                    isSelecting = false
                    selectedTxIDs.removeAll()

                    withAnimation(uiAnim) {
                        store.transactions.removeAll { ids.contains($0.id) }
                    }
                    scheduleUndoCommit()
                }
                Button("Cancel", role: .cancel) {
                    showBulkDeletePopover = false
                }
            } message: {
                Text("This action can’t be undone.")
            }
            .navigationDestination(isPresented: $showImport) {
                ImportTransactionsScreen(store: $store)
            }

        }
        .sheet(isPresented: $showAdd) {
            AddTransactionSheet(store: $store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: editingWrapper) { wrapper in
            EditTransactionSheet(store: $store, transactionID: wrapper.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showFilters) {
            TransactionsFilterSheet(
                selectedCategories: $selectedCategories,
                useDateRange: $useDateRange,
                dateFrom: $dateFrom,
                dateTo: $dateTo,
                minAmountText: $minAmountText,
                maxAmountText: $maxAmountText
            )
        }
        
    }
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            leadingToolbar
        }
        ToolbarItem(placement: .topBarTrailing) {
            trailingToolbar
        }
    }

    @ViewBuilder
    private var leadingToolbar: some View {
        if isSelecting {
            Button("Cancel") {
                isSelecting = false
                selectedTxIDs.removeAll()
                showBulkDeletePopover = false
            }
            .foregroundStyle(DS.Colors.subtext)

            Button("Delete") {
                guard !selectedTxIDs.isEmpty else { return }
                showBulkDeletePopover = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(DS.Colors.danger)
            .disabled(selectedTxIDs.isEmpty)
        } else {
            Button("Select") {
                isSelecting = true
                Haptics.selection()
            }
            .foregroundStyle(DS.Colors.subtext)
        }
    }

    @ViewBuilder
    private var trailingToolbar: some View {
        if isSelecting {
            Button("Select all") {
                selectedTxIDs = Set(filtered.map { $0.id })
                Haptics.selection()
            }
            .foregroundStyle(DS.Colors.subtext)
        } else {
            TransactionsTrailingButtons(
                filtersActive: activeFilterCount > 0,
                showImport: $showImport,
                showFilters: $showFilters,
                showAdd: $showAdd,
                disabled: store.budgetTotal <= 0,
                uiAnim: uiAnim
            )
            .padding(.trailing, 6)
        }
    }

    // Helper binding for .sheet(item:) for edit transaction
    private var editingWrapper: Binding<UUIDWrapper?> {
        Binding<UUIDWrapper?>(
            get: { editingTxID.map { UUIDWrapper(id: $0) } },
            set: { editingTxID = $0?.id }
        )
    }
    // Add new state property for bulk delete popover
    @State private var showBulkDeletePopover = false
}

private struct TransactionsTrailingButtons: View {
    let filtersActive: Bool
    @Binding var showImport: Bool
    @Binding var showFilters: Bool
    @Binding var showAdd: Bool
    let disabled: Bool
    let uiAnim: Animation

    var body: some View {
        HStack(spacing: 12) {
            Button { showImport = true } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(filtersActive ? Color.black : DS.Colors.text)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(filtersActive ? DS.Colors.positive : Color.clear)
                            .animation(uiAnim, value: filtersActive)
                    )
            }
            .buttonStyle(.plain)
            .disabled(disabled)

            Button { showFilters = true } label: {
                Image(systemName: filtersActive
                      ? "line.3.horizontal.decrease.circle.fill"
                      : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(filtersActive ? Color.black : DS.Colors.text)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(filtersActive ? DS.Colors.positive : Color.clear)
                            .animation(uiAnim, value: filtersActive)
                    )
            }
            .buttonStyle(.plain)
            .disabled(disabled)

            Button { showAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(filtersActive ? Color.black : DS.Colors.text)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(filtersActive ? DS.Colors.positive : Color.clear)
                            .animation(uiAnim, value: filtersActive)
                    )
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
    }
}

private struct ImportTransactionsSheet: View {
    @Binding var store: Store

    var body: some View {
        ImportTransactionsScreen(store: $store)
    }
}

private struct TransactionsFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedCategories: Set<Category>
    @Binding var useDateRange: Bool
    @Binding var dateFrom: Date
    @Binding var dateTo: Date
    @Binding var minAmountText: String
    @Binding var maxAmountText: String

    private var allSelected: Bool { selectedCategories.count == Category.allCases.count }
    private let uiAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.0)

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Categories")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Button(allSelected ? "Clear" : "All") {
                                        withAnimation(uiAnim) {
                                            if allSelected {
                                                selectedCategories = []
                                            } else {
                                                selectedCategories = Set(Category.allCases)
                                            }
                                        }
                                    }
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                    .buttonStyle(.plain)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Category.allCases, id: \.self) { c in
                                            let isOn = selectedCategories.contains(c)
                                            Button {
                                                withAnimation(uiAnim) {
                                                    if isOn {
                                                        selectedCategories.remove(c)
                                                    } else {
                                                        selectedCategories.insert(c)
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 8) {
                                                    Image(systemName: c.icon)
                                                    Text(c.title)
                                                }
                                                .font(DS.Typography.caption)
                                                .foregroundStyle(isOn ? DS.Colors.text : DS.Colors.subtext)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 9)
                                                .background(
                                                    (isOn ? c.tint.opacity(0.18) : DS.Colors.surface2),
                                                    in: RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                        .stroke(DS.Colors.grid, lineWidth: 1)
                                                )
                                                .animation(uiAnim, value: selectedCategories)
                                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                if selectedCategories.isEmpty {
                                    Text("Tip: select at least one category.")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }
                            }
                        }

                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Date range")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Toggle("", isOn: $useDateRange)
                                        .onChange(of: useDateRange) { _, _ in
                                            withAnimation(uiAnim) { }
                                        }
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: 0x3A3A3C)))
                                        .animation(uiAnim, value: useDateRange)
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(useDateRange ? Color.clear : DS.Colors.surface2.opacity(0.6))
                                )

                                if useDateRange {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("From")
                                                .font(DS.Typography.caption)
                                                .foregroundStyle(DS.Colors.subtext)
                                            DatePicker("", selection: $dateFrom, displayedComponents: [.date])
                                                .labelsHidden()
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("To")
                                                .font(DS.Typography.caption)
                                                .foregroundStyle(DS.Colors.subtext)
                                            DatePicker("", selection: $dateTo, displayedComponents: [.date])
                                                .labelsHidden()
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                } else {
                                    Text("Off — showing all dates in the selected month.")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                        .transition(.opacity)
                                }
                            }
                        }

                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Amount range")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Min (€)")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        TextField("0.00", text: $minAmountText)
                                            .keyboardType(.decimalPad)
                                            .font(DS.Typography.number)
                                            .padding(10)
                                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(DS.Colors.grid, lineWidth: 1)
                                            )
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Max (€)")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        TextField("0.00", text: $maxAmountText)
                                            .keyboardType(.decimalPad)
                                            .font(DS.Typography.number)
                                            .padding(10)
                                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(DS.Colors.grid, lineWidth: 1)
                                            )
                                    }
                                }

                                Text("Amounts are in EUR. Example: 12.50")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }

                        HStack(spacing: 12) {
                            Button {
                                withAnimation(uiAnim) {
                                    selectedCategories = Set(Category.allCases)
                                    useDateRange = false
                                    dateFrom = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
                                    dateTo = Date()
                                    minAmountText = ""
                                    maxAmountText = ""
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset")
                                }
                            }
                            .buttonStyle(DS.PrimaryButton())

                            Button {
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Apply")
                                }
                            }
                            .buttonStyle(DS.PrimaryButton())
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(DS.Colors.subtext)
                }
            }
        }
    }
}

// MARK: - Budget

private struct BudgetView: View {
    @Binding var store: Store

    @State private var editingTotal = ""
    @State private var editingCategoryBudgets: [Category: String] = [:]
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
                                TextField("e.g. 3000.00", text: $editingTotal)
                                    .keyboardType(.decimalPad)
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
                                    let v = DS.Format.cents(from: editingTotal)
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
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Category budgets")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                Text("Optional: set caps per category. Leave empty for no cap.")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                Divider().overlay(DS.Colors.grid)

                                VStack(spacing: 10) {
                                    ForEach(Category.allCases, id: \.self) { c in
                                        HStack(spacing: 10) {
                                            HStack(spacing: 8) {
                                                Circle()
                                                    .fill(c.tint.opacity(0.18))
                                                    .frame(width: 26, height: 26)
                                                    .overlay(
                                                        Image(systemName: c.icon)
                                                            .foregroundStyle(c.tint)
                                                            .font(.system(size: 12, weight: .semibold))
                                                    )
                                                Text(c.title)
                                                    .font(DS.Typography.body)
                                                    .foregroundStyle(DS.Colors.text)
                                            }
                                            Spacer()

                                            TextField("0.00", text: Binding(
                                                get: { editingCategoryBudgets[c] ?? "" },
                                                set: { newVal in
                                                    editingCategoryBudgets[c] = newVal
                                                    let v = DS.Format.cents(from: newVal)
                                                    store.setCategoryBudget(v, for: c)
                                                }
                                            ))
                                            .keyboardType(.decimalPad)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .multilineTextAlignment(.trailing)
                                            .font(DS.Typography.number)
                                            .padding(10)
                                            .frame(width: 120)
                                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(DS.Colors.grid, lineWidth: 1)
                                            )
                                        }
                                    }
                                }

                                Divider().overlay(DS.Colors.grid)

                                let allocated = store.totalCategoryBudgets()
                                let remainingToAllocate = store.budgetTotal - allocated

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Allocated")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Text(DS.Format.money(allocated))
                                            .font(DS.Typography.number)
                                            .foregroundStyle(DS.Colors.text)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Unallocated")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Text(DS.Format.money(remainingToAllocate))
                                            .font(DS.Typography.number)
                                            .foregroundStyle(remainingToAllocate >= 0 ? DS.Colors.text : DS.Colors.danger)
                                    }
                                }

                                if allocated > store.budgetTotal {
                                    DS.StatusLine(
                                        title: "Category caps exceed total budget",
                                        detail: "Reduce one or more category budgets so allocation stays within the monthly total.",
                                        level: .watch
                                    )
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
                editingTotal = store.budgetTotal > 0
                    ? String(format: "%.2f", Double(store.budgetTotal) / 100.0)
                    : ""
                var map: [Category: String] = [:]
                for c in Category.allCases {
                    let v = store.categoryBudget(for: c)
                    map[c] = v > 0 ? String(format: "%.2f", Double(v) / 100.0) : ""
                }
                editingCategoryBudgets = map
            }
        }
    }
}

// MARK: - Insights

private struct InsightsView: View {
    @Binding var store: Store
    let goToBudget: () -> Void
    @State private var showAI: Bool = false
    
    @AppStorage("notifications.enabled") private var notificationsEnabled: Bool = false
    @State private var notifDetail: String? = nil
    
    @State private var shareURL: URL? = nil
    @State private var showShareSheet: Bool = false

    private struct TrendPoint: Identifiable {
        let id: Int          // day of month
        let euros: Double
    }

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

                                Text("Projection uses a robust daily average (reduces the impact of one unusual day). New transactions refine the estimate.")
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
                                HStack {
                                    Text("Notifications")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Toggle("", isOn: $notificationsEnabled)
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: 0x3A3A3C)))
                                }

                                Text("Get reminders to review your budget and spending.")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                if let notifDetail {
                                    DS.StatusLine(
                                        title: "Notification status",
                                        detail: notifDetail,
                                        level: notificationsEnabled ? .ok : .watch
                                    )
                                }

                                Button {
                                    Task { await sendTestNotification() }
                                } label: {
                                    HStack {
                                        Image(systemName: "bell.badge")
                                        Text("Send test notification")
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .disabled(!notificationsEnabled)

                                Text("Tip: turn notifications on, then tap the test button.")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }
                        
                        
                        
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Export")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Text("Share")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }

                                Text("Export your month as a clean table for Excel or as CSV.")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                HStack(spacing: 10) {
                                    Button {
                                        exportMonth(format: .excel)
                                    } label: {
                                        HStack {
                                            Image(systemName: "tablecells")
                                            Text("Excel")
                                        }
                                    }
                                    .buttonStyle(DS.PrimaryButton())

                                    Button {
                                        exportMonth(format: .csv)
                                    } label: {
                                        HStack {
                                            Image(systemName: "doc.plaintext")
                                            Text("CSV")
                                        }
                                    }
                                    .buttonStyle(DS.PrimaryButton())
                                }

                                Text("Tip: Excel export includes multiple sheets (Summary, Transactions, Categories, Daily).")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }
                        
                        
                        
                        

                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("AI analysis")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Text("Powered by cloud")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }

                                Text("Get a smarter explanation of what drove your spending and what to do next.")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                Button {
                                    showAI = true
                                } label: {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                        Text("Analyze this month")
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                            }
                        }
                        .sheet(isPresented: $showAI) {
                            AIInsightsView(store: $store)
                                .presentationDetents([.large])
                                .presentationDragIndicator(.visible)
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
            .onChange(of: notificationsEnabled) { _, newVal in
                if newVal {
                    Task {
                        await requestNotificationPermissionIfNeeded()
                        // Once permission is granted, schedule recurring reminders and evaluate rules.
                        await Notifications.syncAll(store: store)
                    }
                } else {
                    // Turning off only disables in-app usage; iOS-level permission stays in Settings.
                    notifDetail = "Notifications are turned off in the app."
                    Notifications.cancelAll()
                }
            }
            .onAppear {
                // Allow notifications to show even when the app is open (foreground).
                UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared

                if notificationsEnabled {
                    Task {
                        // Keep schedules fresh when returning to this screen.
                        await Notifications.syncAll(store: store)
                    }
                }
            }
            .onChange(of: store) { _, _ in
                // Re-evaluate smart rules as data changes (budget/transactions/etc.).
                guard notificationsEnabled else { return }
                Task { await Notifications.evaluateSmartRules(store: store) }
            }
            
            .sheet(isPresented: $showShareSheet) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
                        .ignoresSafeArea()
                }
            }
        }
    }


    private func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                notifDetail = "Enabled. You can send a test notification now."
            }
            await Notifications.syncAll(store: store)
        case .denied:
            await MainActor.run {
                notificationsEnabled = false
                notifDetail = "Notifications are blocked in iOS Settings for this app. Enable them in Settings → Notifications."
            }
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                await MainActor.run {
                    if granted {
                        notifDetail = "Permission granted. Tap ‘Send test notification’."
                    } else {
                        notificationsEnabled = false
                        notifDetail = "Permission not granted. Toggle stayed off."
                    }
                }
                if granted {
                    await Notifications.syncAll(store: store)
                }
            } catch {
                await MainActor.run {
                    notificationsEnabled = false
                    notifDetail = "Couldn’t request permission: \(error.localizedDescription)"
                }
            }
        @unknown default:
            await MainActor.run {
                notifDetail = "Unknown notification status."
            }
        }
    }

    private func sendTestNotification() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        guard notificationsEnabled else {
            await MainActor.run { notifDetail = "Turn notifications on first." }
            return
        }

        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else {
            await MainActor.run {
                notificationsEnabled = false
                notifDetail = "Notifications are not authorized. Please enable them in iOS Settings."
            }
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: ["balance.test.notification"])

        let content = UNMutableNotificationContent()
        content.title = "Balance — Test"
        content.body = "This is a test notification. If you see this, notifications are working."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let req = UNNotificationRequest(identifier: "balance.test.notification", content: content, trigger: trigger)

        do {
            try await center.add(req)
            await MainActor.run {
                notifDetail = "Test notification scheduled (in ~3 seconds)."
            }
        } catch {
            await MainActor.run {
                notifDetail = "Failed to schedule notification: \(error.localizedDescription)"
            }
        }
    }
    
    private enum ExportFormat {
        case csv
        case excel

        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .excel: return "xlsx" // Office Open XML (zipped container)
            }
        }
    }

    private func exportMonth(format: ExportFormat) {
        let summary = Analytics.monthSummary(store: store)
        let tx = Analytics.monthTransactions(store: store)
        let dailyPoints = Analytics.dailySpendPoints(store: store)
        let cats = Analytics.categoryBreakdown(store: store)

        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: store.selectedMonth)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let monthKey = String(format: "%04d-%02d", y, m)

        let filename = "Balance_\(monthKey).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            let data: Data
            switch format {
            case .csv:
                let csv = Exporter.makeCSV(
                    monthKey: monthKey,
                    currency: "EUR",
                    budgetCents: store.budgetTotal,
                    summary: summary,
                    transactions: tx,
                    categories: cats,
                    daily: dailyPoints
                )
                data = csv.data(using: String.Encoding.utf8) ?? Data()
            case .excel:
                let caps: [Category: Int] = Dictionary(uniqueKeysWithValues: Category.allCases.map { ($0, store.categoryBudget(for: $0)) })
                data = Exporter.makeXLSX(
                    monthKey: monthKey,
                    currency: "EUR",
                    budgetCents: store.budgetTotal,
                    categoryCapsCents: caps,
                    summary: summary,
                    transactions: tx,
                    categories: cats,
                    daily: dailyPoints
                )
            }

            try data.write(to: url, options: .atomic)
            self.shareURL = url
            self.showShareSheet = true
        } catch {
            self.notifDetail = "Export failed: \(error.localizedDescription)"
        }
    }
}

private struct AIInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var store: Store

    // Set this to your Cloudflare Worker endpoint.
    private let endpoint = URL(string: "https://empty-breeze-77fb.mani-acc7282.workers.dev/analyze")!

    @State private var isLoading: Bool = false
    @State private var errorText: String? = nil
    @State private var result: AIAnalysisResult? = nil
    @State private var lastAnalyzedAt: Date? = nil

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return fmt.string(from: store.selectedMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("AI insights")
                                        .font(DS.Typography.title)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Button("Close") { dismiss() }
                                        .foregroundStyle(DS.Colors.subtext)
                                }

                                Text("\(monthTitle)")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)

                                Text(
                                    "Tip: AI-generated insights based on your spending data. Results may be imperfect — use as guidance."
                                )
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)

                                if let errorText {
                                    DS.StatusLine(
                                        title: "Couldn’t analyze",
                                        detail: errorText,
                                        level: .watch
                                    )
                                }

                                if isLoading {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                        Text("Analyzing…")
                                            .font(DS.Typography.body)
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                    .padding(.vertical, 6)
                                }

                                Button {
                                    Task { await analyze() }
                                } label: {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text(result == nil ? "Run analysis" : "Re-analyze")
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .disabled(isLoading)

                                if let lastAnalyzedAt {
                                    Text("Last analyzed: \(DS.Format.relativeDateTime(lastAnalyzedAt))")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }
                            }
                        }

                        if let result {
                            DS.Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Summary")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)

                                    Text(result.summary)
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.text)
                                }
                            }

                            DS.Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Insights")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)

                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(result.insights, id: \.self) { s in
                                            Text("• \(s)")
                                                .font(DS.Typography.body)
                                                .foregroundStyle(DS.Colors.text)
                                        }
                                    }
                                }
                            }

                            DS.Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Recommended actions")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)

                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(result.actions, id: \.self) { s in
                                            Text("• \(s)")
                                                .font(DS.Typography.body)
                                                .foregroundStyle(DS.Colors.text)
                                        }
                                    }
                                }
                            }

                            DS.Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Risk")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)

                                    DS.StatusLine(
                                        title: "Risk level",
                                        detail: result.riskLevel.uppercased(),
                                        level: result.riskLevelLevel
                                    )
                                }
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadCachedResultIfAvailable()
        }
    }

    private func analyze() async {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let payload = AIAnalysisPayload.from(store: store)
            let reqData = try JSONEncoder().encode(payload)

            var req = URLRequest(url: endpoint)
            req.httpMethod = "POST"
            req.httpBody = reqData
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw NSError(domain: "AI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error \(http.statusCode). \(body)"])
            }

            let decoded = try JSONDecoder().decode(AIAnalysisResult.self, from: data)
            result = decoded
            lastAnalyzedAt = Date()
            saveCachedResult(decoded, analyzedAt: lastAnalyzedAt!)
        } catch {
            errorText = error.localizedDescription
        }
    }


    private var cacheKey: String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: store.selectedMonth)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        return String(format: "ai.analysis.%04d-%02d", y, m)
    }

    private func loadCachedResultIfAvailable() {
        // Load cached analysis per-month so reopening the sheet does not re-run.
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }
        do {
            let cached = try JSONDecoder().decode(AICachedAnalysis.self, from: data)
            self.result = cached.result
            self.lastAnalyzedAt = cached.analyzedAt
        } catch {
            // If cache is corrupted or schema changed, ignore.
        }
    }

    private func saveCachedResult(_ result: AIAnalysisResult, analyzedAt: Date) {
        let cached = AICachedAnalysis(result: result, analyzedAt: analyzedAt)
        do {
            let data = try JSONEncoder().encode(cached)
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            // Ignore cache save failures.
        }
    }
}


private struct AICachedAnalysis: Codable {
    let result: AIAnalysisResult
    let analyzedAt: Date
}

private struct AIAnalysisPayload: Codable {
    struct DayTotal: Codable { let day: Int; let amount: Int }
    struct CategoryTotal: Codable { let name: String; let amount: Int }

    let month: String
    let budget: Int
    let totalSpent: Int
    let remaining: Int
    let dailyAvg: Int
    let daily: [DayTotal]
    let categories: [CategoryTotal]

    static func from(store: Store) -> AIAnalysisPayload {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: store.selectedMonth)
        let year = comps.year ?? 0
        let monthNum = comps.month ?? 0
        let monthStr = String(format: "%04d-%02d", year, monthNum)

        let summary = Analytics.monthSummary(store: store)
        let points = Analytics.dailySpendPoints(store: store)
        let breakdown = Analytics.categoryBreakdown(store: store)

        let daily = points.map { DayTotal(day: $0.day, amount: $0.amount) }
        let cats = breakdown.map { CategoryTotal(name: $0.category.title, amount: $0.total) }

        return AIAnalysisPayload(
            month: monthStr,
            budget: store.budgetTotal,
            totalSpent: summary.totalSpent,
            remaining: summary.remaining,
            dailyAvg: summary.dailyAvg,
            daily: daily,
            categories: cats
        )
    }
}

private struct AIAnalysisResult: Codable {
    let summary: String
    let insights: [String]
    let actions: [String]
    let riskLevel: String

    var riskLevelLevel: Level {
        switch riskLevel.lowercased() {
        case "ok": return .ok
        case "watch": return .watch
        case "risk": return .risk
        default: return .watch
        }
    }
}

// MARK: - Components

private struct CategoryTotalRow: View {
    let category: Category
    let spent: Int

    var body: some View {
        HStack {
            Text(category.title)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.text)
            Spacer()
            Text(DS.Format.money(spent))
                .font(DS.Typography.number)
                .foregroundStyle(DS.Colors.text)
        }
        .padding(12)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
}

private struct CategoryCapRow: View {
    let category: Category
    let spent: Int
    let cap: Int

    private var usedRatioRaw: Double {
        cap > 0 ? Double(spent) / Double(cap) : 0
    }

    private var barRatio: Double {
        min(1, max(0, usedRatioRaw))
    }

    private var levelColor: Color {
        if usedRatioRaw >= 1.0 { return DS.Colors.danger }
        if usedRatioRaw >= 0.90 { return DS.Colors.warning }
        return DS.Colors.positive
    }

    var body: some View {
        let remaining = cap - spent

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(category.title)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.text)

                Spacer()

                Text(DS.Format.money(spent))
                    .font(DS.Typography.number)
                    .foregroundStyle(DS.Colors.text)
            }

            HStack {
                Text("Category cap")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)

                Spacer()

                Text("\(DS.Format.percent(usedRatioRaw)) used")
                    .font(DS.Typography.caption)
                    .foregroundStyle(usedRatioRaw >= 0.90 ? levelColor : DS.Colors.subtext)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(DS.Colors.surface)

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(levelColor)
                        .frame(width: geo.size.width * barRatio)
                        .opacity(0.85)
                        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: barRatio)
                }
            }
            .frame(height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(DS.Colors.grid, lineWidth: 1)
            )

            HStack {
                Text("Cap: \(DS.Format.money(cap))")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)

                Spacer()

                if remaining >= 0 {
                    Text("Remaining: \(DS.Format.money(remaining))")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                } else {
                    Text("Over: \(DS.Format.money(abs(remaining)))")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.danger)
                }
            }
        }
        .padding(12)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
}

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
                Haptics.selection()
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(DS.Colors.subtext)
                    .padding(8)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                Haptics.light()
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
                Haptics.selection()
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


private struct TransactionFormCard: View {
    @Binding var amountText: String
    @Binding var note: String
    @Binding var date: Date
    @Binding var category: Category

    var body: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Amount")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)

                TextField("e.g. 250.00", text: $amountText)
                    .keyboardType(.decimalPad)
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
                                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: category)
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

                
                TransactionFormCard(
                    amountText: $amountText,
                    note: $note,
                    date: $date,
                    category: $category
                )

                Button {
                    let amount = DS.Format.cents(from: amountText)
                    guard amount > 0 else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        store.add(Transaction(amount: amount, date: date, category: category, note: note))
                    }
                    Haptics.success()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save")
                    }
                }
                .buttonStyle(DS.PrimaryButton())
                .disabled(DS.Format.cents(from: amountText) <= 0)

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

                TransactionFormCard(
                    amountText: $amountText,
                    note: $note,
                    date: $date,
                    category: $category
                )

                Button {
                    guard let idx = index else { return }
                    let amount = DS.Format.cents(from: amountText)
                    guard amount > 0 else { return }

                    let existingID = store.transactions[idx].id
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        store.transactions[idx] = Transaction(
                            id: existingID,
                            amount: amount,
                            date: date,
                            category: category,
                            note: note
                        )
                    }
                    Haptics.success()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save changes")
                    }
                }
                .buttonStyle(DS.PrimaryButton())
                .disabled(DS.Format.cents(from: amountText) <= 0 || index == nil)

                Spacer()
            }
            .padding(16)
        }
        .onAppear {
            guard let idx = index else { return }
            let t = store.transactions[idx]
            amountText = String(format: "%.2f", Double(t.amount) / 100.0)
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
        static let warning  = Color(hex: 0xFF9F0A)   // orange (watch)
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
                        .stroke(DS.Colors.grid, lineWidth: 1)
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
                    .stroke(DS.Colors.grid, lineWidth: 1)
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
            // 0–70%: ok (green), 70–80%: watch (orange), 80%+: risk (red)
            if ratio < 0.70 { return .ok }
            if ratio <= 0.80 { return .watch }
            return .risk
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
                        .foregroundStyle(level == .ok ? Colors.subtext : level.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Colors.surface2)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(level.color)
                            .frame(width: geo.size.width * ratio)
                            .opacity(0.85)
                            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: ratio)
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
        static func money(_ cents: Int) -> String {
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.locale = .current
            nf.currencyCode = "EUR"
            nf.currencySymbol = "€"
            nf.minimumFractionDigits = 2
            nf.maximumFractionDigits = 2

            let value = Decimal(cents) / Decimal(100)
            return nf.string(from: value as NSDecimalNumber) ?? "€\(value)"
        }

        static func percent(_ value: Double) -> String {
            let nf = NumberFormatter()
            nf.numberStyle = .percent
            nf.locale = .current
            nf.minimumFractionDigits = 0
            nf.maximumFractionDigits = 0
            return nf.string(from: NSNumber(value: value)) ?? "\(Int(value * 100))%"
        }

        /// Parses user-entered money text into **euro cents**.
        /// Accepts: "250", "250.5", "250.50", "250,50"
        static func cents(from text: String) -> Int {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return 0 }

            var cleaned = ""
            var didAddDot = false

            for ch in trimmed {
                if ch.isNumber {
                    cleaned.append(ch)
                } else if (ch == "." || ch == ",") && !didAddDot {
                    cleaned.append(".")
                    didAddDot = true
                }
            }

            guard !cleaned.isEmpty else { return 0 }

            // If no decimal separator: treat as euros (e.g. "250" => 25000 cents)
            if !cleaned.contains(".") {
                let euros = Int(cleaned) ?? 0
                return max(0, euros * 100)
            }

            let dec = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) ?? 0
            let centsDec = dec * Decimal(100)
            let cents = NSDecimalNumber(decimal: centsDec).rounding(accordingToBehavior: nil).intValue
            return max(0, cents)
        }

        static func relativeDateTime(_ date: Date) -> String {
            let fmt = RelativeDateTimeFormatter()
            fmt.locale = .current
            fmt.unitsStyle = .abbreviated
            return fmt.localizedString(for: date, relativeTo: Date())
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
    /// Optional per-category budgets per month, stored in euro cents.
    /// Outer key: YYYY-MM, inner key: Category.rawValue
    var categoryBudgetsByMonth: [String: [String: Int]] = [:]
    var transactions: [Transaction] = []

    static func monthKey(_ date: Date) -> String {
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
    
    func categoryBudget(for category: Category, month: Date) -> Int {
        categoryBudgetsByMonth[Self.monthKey(month)]?[category.rawValue] ?? 0
    }

    /// Category budget for the currently selected month.
    func categoryBudget(for category: Category) -> Int {
        categoryBudget(for: category, month: selectedMonth)
    }

    mutating func setCategoryBudget(_ value: Int, for category: Category, month: Date) {
        let key = Self.monthKey(month)
        var m = categoryBudgetsByMonth[key] ?? [:]
        m[category.rawValue] = max(0, value)
        categoryBudgetsByMonth[key] = m
    }

    mutating func setCategoryBudget(_ value: Int, for category: Category) {
        setCategoryBudget(value, for: category, month: selectedMonth)
    }

    func totalCategoryBudgets(for month: Date) -> Int {
        let key = Self.monthKey(month)
        return (categoryBudgetsByMonth[key] ?? [:]).values.reduce(0, +)
    }

    func totalCategoryBudgets() -> Int {
        totalCategoryBudgets(for: selectedMonth)
    }

    mutating func add(_ t: Transaction) { transactions.append(t) }

    mutating func deleteTransactions(in items: [Transaction], offsets: IndexSet) {
        let toDelete = offsets.map { items[$0].id }
        transactions.removeAll { toDelete.contains($0.id) }
    }

    mutating func delete(id: UUID) {
        transactions.removeAll { $0.id == id }
    }

    mutating func clearMonthData(for month: Date) {
        let key = Self.monthKey(month)
        let cal = Calendar.current

        // حذف تمام تراکنش‌های ماه
        transactions.removeAll {
            cal.isDate($0.date, equalTo: month, toGranularity: .month)
        }

        // حذف بودجه کل ماه
        budgetsByMonth.removeValue(forKey: key)

        // حذف سقف‌های دسته‌بندی
        categoryBudgetsByMonth.removeValue(forKey: key)
    }
    
    /// Returns true if the given month has any stored data (transactions or budgets/caps).
    func hasMonthData(for month: Date) -> Bool {
        let key = Self.monthKey(month)
        let cal = Calendar.current

        let hasTx = transactions.contains { cal.isDate($0.date, equalTo: month, toGranularity: .month) }
        let hasBudget = (budgetsByMonth[key] ?? 0) > 0
        let hasCaps = (categoryBudgetsByMonth[key] ?? [:]).values.contains { $0 > 0 }

        return hasTx || hasBudget || hasCaps
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

    /// Returns a status line if any category cap is near/over for the selected month.
    /// Shows RISK immediately when over; otherwise WATCH when >= 90% used.
    static func categoryCapPressure(store: Store) -> Pressure? {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return nil }

        var bestWatch: Pressure? = nil

        for c in Category.allCases {
            let cap = store.categoryBudget(for: c)
            guard cap > 0 else { continue }

            let spent = tx.filter { $0.category == c }.reduce(0) { $0 + $1.amount }
            guard spent > 0 else { continue }

            if spent > cap {
                let over = spent - cap
                return .init(
                    title: "Over cap: \(c.title)",
                    detail: "You’re \(DS.Format.money(over)) above your \(DS.Format.money(cap)) cap.",
                    level: .risk
                )
            }

            let ratio = Double(spent) / Double(max(1, cap))
            if ratio >= 0.9 {
                bestWatch = .init(
                    title: "Near cap: \(c.title)",
                    detail: "Used \(DS.Format.percent(ratio)) of your \(DS.Format.money(cap)) cap.",
                    level: .watch
                )
            }
        }

        return bestWatch
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

        // Robust daily average (outlier-resistant): winsorize daily totals across elapsed days.
        // This reduces the impact of a single unusually large day early in the month.
        let tx = monthTransactions(store: store)
        var byDay: [Int: Int] = [:]
        for t in tx {
            let d = calendar.component(.day, from: t.date)
            byDay[d, default: 0] += t.amount
        }

        // Include zero-spend days up to `elapsed` so one big day doesn't dominate.
        let dailyTotals: [Int] = (1...elapsed).map { byDay[$0] ?? 0 }

        func winsorizedMean(_ xs: [Int]) -> Double {
            guard !xs.isEmpty else { return 0 }
            if xs.count < 5 {
                // Not enough data: fall back to plain mean.
                let sum = xs.reduce(0, +)
                return Double(sum) / Double(max(1, xs.count))
            }

            let s = xs.sorted()
            let n = s.count
            let lowIdx = Int(Double(n) * 0.10)
            let highIdx = max(lowIdx, Int(Double(n) * 0.90) - 1)

            let low = s[min(max(0, lowIdx), n - 1)]
            let high = s[min(max(0, highIdx), n - 1)]

            let clampedSum = xs.reduce(0) { acc, v in
                acc + min(max(v, low), high)
            }
            return Double(clampedSum) / Double(n)
        }

        let robustDailyAvg = winsorizedMean(dailyTotals)
        let projected = Int((robustDailyAvg * Double(daysInMonth)).rounded())

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
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("EEEE, MMM d")

        return groups
            .map { (day, items) in
                DayGroup(day: day, title: fmt.string(from: day), items: items.sorted { $0.date > $1.date })
            }
            .sorted { $0.day > $1.day }
    }

    static func generateInsights(store: Store) -> [Insight] {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return [] }

        var out: [Insight] = []

        // Only run projection and breakdown with enough data
        if tx.count >= 5 {
            let proj = projectedEndOfMonth(store: store)
            if proj.level != .ok {
                let title = proj.level == .risk ? "This trend will pressure your budget" : "Approaching the limit"
                let detail = proj.level == .risk
                    ? "End-of-month projection is above budget. Prioritize cutting discretionary costs."
                    : "To stay in control, trim one discretionary category slightly."
                out.append(.init(title: title, detail: detail, level: proj.level))
            } else {
                out.append(.init(title: "Good control", detail: "Current trend aligns with your Main budget. Keep it steady.", level: .ok))
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
        }

        // Category budget caps (optional)
        for c in Category.allCases {
            let cap = store.categoryBudget(for: c)
            guard cap > 0 else { continue }

            let spent = tx.filter { $0.category == c }.reduce(0) { $0 + $1.amount }

            if spent > cap {
                let over = spent - cap
                out.append(.init(
                    title: "Over budget in “\(c.title)”",
                    detail: "You’re \(DS.Format.money(over)) above your \(DS.Format.money(cap)) cap for this category.",
                    level: .risk
                ))
            } else {
                let ratio = Double(spent) / Double(max(1, cap))
                if ratio >= 0.9 {
                    out.append(.init(
                        title: "Near the cap in “\(c.title)”",
                        detail: "You’ve used \(DS.Format.percent(ratio)) of your \(DS.Format.money(cap)) cap.",
                        level: .watch
                    ))
                }
            }
        }

        // Only run smalls, discretionary, over budget with enough data
        if tx.count >= 5 {
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
        }

        return out.sorted { rank($0.level) > rank($1.level) }
    }

    static func quickActions(store: Store) -> [String] {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return [] }

        var actions: [String] = []
        // Category cap driven actions (show even with few transactions)
        for c in Category.allCases {
            let cap = store.categoryBudget(for: c)
            guard cap > 0 else { continue }

            let spent = tx.filter { $0.category == c }.reduce(0) { $0 + $1.amount }
            if spent > cap {
                actions.append("Pause spending in “\(c.title)” for the rest of the month or reduce it sharply.")
                break
            }

            let ratio = Double(spent) / Double(max(1, cap))
            if ratio >= 0.9 {
                actions.append("You’re close to the “\(c.title)” cap—set a mini-cap for the next 7 days.")
                break
            }
        }

        // Only show projection/top-category actions with enough data
        if tx.count >= 5 {
            let proj = projectedEndOfMonth(store: store)

            if proj.level == .risk {
                actions.append("Set a daily spending cap for the next 7 days.")
                actions.append("Temporarily limit one discretionary category (Dining / Entertainment / Shopping).")
            }

            if let top = categoryBreakdown(store: store).first {
                actions.append("Set a weekly cap for “\(top.category.title)”.")
            }
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

// MARK: - Notifications

private final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()

    // Show notifications even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Banner + sound makes the test + future reminders visible while the app is open.
        return [.banner, .sound]
    }
}

private enum Notifications {
    // Identifiers
    private static let dailyID = "balance.notif.daily"
    private static let weeklyID = "balance.notif.weekly"
    private static let paydayID = "balance.notif.payday"

    // Smart (one-off) identifiers are built from these prefixes
    private static let t70Prefix = "balance.notif.threshold70."
    private static let t80Prefix = "balance.notif.threshold80."
    private static let overBudgetPrefix = "balance.notif.overbudget."
    private static let overspendPrefix = "balance.notif.overspend."
    private static let categoryPrefix = "balance.notif.categorycap."

    // Persist “already notified” markers
    private static func monthKey(_ date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    static func syncAll(store: Store) async {
        // If not authorized, do nothing.
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else { return }

        scheduleDailyReminder()
        scheduleWeeklyCheckIn()
        schedulePaydayReminder()

        await evaluateSmartRules(store: store)
    }

    // 1) Daily reminder (simple)
    private static func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])

        var dc = DateComponents()
        dc.hour = 20
        dc.minute = 30

        let content = UNMutableNotificationContent()
        content.title = "Balance"
        content.body = "Quick check: did you log today’s expenses?"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger)
        center.add(req)
    }

    // 2) Weekly check-in (simple)
    private static func scheduleWeeklyCheckIn() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [weeklyID])

        // Sunday 18:00 (can be changed later in Settings)
        var dc = DateComponents()
        dc.weekday = 1 // Sunday
        dc.hour = 18
        dc.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Balance — Weekly check"
        content.body = "Take 60 seconds to review this week’s spending and adjust next week."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: weeklyID, content: content, trigger: trigger)
        center.add(req)
    }

    // 7) Payday reminder (simple: 1st of month at 09:00)
    private static func schedulePaydayReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [paydayID])

        var dc = DateComponents()
        dc.day = 1
        dc.hour = 9
        dc.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Balance — New month"
        content.body = "New month started. Set your budget and category caps for better control."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: paydayID, content: content, trigger: trigger)
        center.add(req)
    }

    // Smart rules (evaluated while user uses the app)
    static func evaluateSmartRules(store: Store) async {
        guard store.budgetTotal > 0 else { return }

        let mKey = monthKey(store.selectedMonth)
        let summary = Analytics.monthSummary(store: store)

        // 3) Monthly budget notifications (edge-triggered)
        // If user goes over budget, notify once. If they later go back under (e.g., edit/delete), reset so crossing again notifies again.
        let overKey = overBudgetPrefix + mKey
        let isOverNow = summary.spentRatio >= 1.0

        if !isOverNow {
            // Reset once we are back under budget.
            UserDefaults.standard.removeObject(forKey: overKey)
        }

        let alreadyOverBudgetNotified = UserDefaults.standard.bool(forKey: overKey)
        if isOverNow {
            if !alreadyOverBudgetNotified {
                // Mark and send immediately
                UserDefaults.standard.set(true, forKey: overKey)
                await scheduleImmediate(
                    id: overKey,
                    title: "Over budget",
                    body: "You’re over your monthly budget. Review spending and pause non‑essentials until month end."
                )
            }
        } else {
            // Repeatable 70/80 alerts while not over-budget.
            // 70/80 alerts (edge-triggered, once per month).
            // We keep a simple state so entering Insights or re-evaluations don't spam.
            let thresholdStateKey = "balance.notif.threshold.state." + mKey
            let lastState = UserDefaults.standard.string(forKey: thresholdStateKey) ?? "none" // none | t70 | t80

            let newState: String
            if summary.spentRatio >= 0.80 {
                newState = "t80"
            } else if summary.spentRatio >= 0.70 {
                newState = "t70"
            } else {
                newState = "none"
            }

            if newState == "none" {
                // Reset once we are back under 70% so future crossings can notify again.
                if lastState != "none" {
                    UserDefaults.standard.removeObject(forKey: thresholdStateKey)
                }
            } else {
                // Only notify on upward transitions (none -> t70, t70 -> t80, none -> t80).
                let shouldNotify: Bool
                if lastState == "none" {
                    shouldNotify = true
                } else if lastState == "t70" && newState == "t80" {
                    shouldNotify = true
                } else {
                    shouldNotify = false
                }

                if shouldNotify {
                    UserDefaults.standard.set(newState, forKey: thresholdStateKey)

                    if newState == "t70" {
                        let id = t70Prefix + mKey
                        await scheduleImmediate(
                            id: id,
                            title: "Budget alert",
                            body: "You’ve used 70% of your monthly budget. Consider trimming discretionary spending this week."
                        )
                    } else {
                        let id = t80Prefix + mKey
                        await scheduleImmediate(
                            id: id,
                            title: "Budget warning",
                            body: "You’ve used 80% of your monthly budget. Tighten spending to avoid exceeding your limit."
                        )
                    }
                }
            }
        }

        // 4) Overspend today vs daily cap — notify every time rule is evaluated
        

        // 5) Category cap near/over — edge-triggered per category per month
        let monthTx = Analytics.monthTransactions(store: store)
        for c in Category.allCases {
            let cap = store.categoryBudget(for: c)
            guard cap > 0 else { continue }

            let spent = monthTx.filter { $0.category == c }.reduce(0) { $0 + $1.amount }
            let ratio = Double(spent) / Double(max(1, cap))

            // Track last state so we only notify on transitions.
            // States: none (<0.90), near (>=0.90 and <1.0), over (>=1.0)
            let stateKey = categoryPrefix + "state." + mKey + "." + c.rawValue
            let lastState = (UserDefaults.standard.string(forKey: stateKey) ?? "none")

            let newState: String
            if ratio >= 1.0 {
                newState = "over"
            } else if ratio >= 0.90 {
                newState = "near"
            } else {
                newState = "none"
            }

            // Reset when back below threshold so future crossings notify again.
            if newState == "none" {
                if lastState != "none" {
                    UserDefaults.standard.removeObject(forKey: stateKey)
                }
                continue
            }

            // Transition: none -> near, near -> over, none -> over
            if newState != lastState {
                UserDefaults.standard.set(newState, forKey: stateKey)

                if newState == "over" {
                    let over = max(0, spent - cap)
                    let overPct = cap > 0 ? Double(over) / Double(cap) : 0
                    let id = categoryPrefix + UUID().uuidString
                    await scheduleImmediate(
                        id: id,
                        title: "Category cap exceeded",
                        body: "\(c.title): \(DS.Format.percent(overPct)) over cap (\(DS.Format.money(over)) above \(DS.Format.money(cap)))"
                    )
                } else {
                    let id = categoryPrefix + UUID().uuidString
                    await scheduleImmediate(
                        id: id,
                        title: "Approaching category cap",
                        body: "\(c.title): used \(DS.Format.percent(min(1.5, ratio))) of your \(DS.Format.money(cap)) cap."
                    )
                }
            }
        }
    }


    // Send helpers
    private static func sendOncePerMonth(id: String, title: String, body: String) async {
        // Marker is stored in UserDefaults so we don’t spam.
        let ud = UserDefaults.standard
        if ud.bool(forKey: id) { return }
        ud.set(true, forKey: id)
        await scheduleImmediate(id: id, title: title, body: body)
    }

    private static func sendOnce(id: String, title: String, body: String) async {
        let ud = UserDefaults.standard
        if ud.bool(forKey: id) { return }
        ud.set(true, forKey: id)
        await scheduleImmediate(id: id, title: title, body: body)
    }

    private static func scheduleImmediate(id: String, title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Deliver immediately (no trigger). This removes the noticeable delay.
        let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        do {
            try await center.add(req)
        } catch {
            // ignore
        }
    }
}



private enum Exporter {
    // MARK: - XLSX (real Office Open XML container)
    static func makeXLSX(
        monthKey: String,
        currency: String,
        budgetCents: Int,
        categoryCapsCents: [Category: Int],
        summary: Analytics.MonthSummary,
        transactions: [Transaction],
        categories: [Analytics.CategoryRow],
        daily: [Analytics.DayPoint]
    ) -> Data {
        // Build worksheets (richer export)
        let generatedAt = Date()
        let generatedFmt = DateFormatter()
        generatedFmt.locale = .current
        generatedFmt.dateFormat = "yyyy-MM-dd HH:mm:ss"

        // Parse YYYY-MM
        let parts = monthKey.split(separator: "-")
        let y = Int(parts.first ?? "0") ?? 0
        let m = Int(parts.dropFirst().first ?? "0") ?? 0

        let cal = Calendar.current
        var monthComps = DateComponents()
        monthComps.year = y
        monthComps.month = m
        monthComps.day = 1
        let monthDate = cal.date(from: monthComps) ?? Date()

        let dayNameFmt = DateFormatter()
        dayNameFmt.locale = .current
        dayNameFmt.dateFormat = "EEE" // Mon, Tue...

        // Category maps
        let spentByCategory: [Category: Int] = Dictionary(uniqueKeysWithValues: categories.map { ($0.category, $0.total) })
        let txCountByCategory: [Category: Int] = {
            var out: [Category: Int] = [:]
            for t in transactions { out[t.category, default: 0] += 1 }
            return out
        }()

        let totalSpentCents = categories.reduce(0) { $0 + $1.total }

        // Summary sheet
        let summaryRows: [[Cell]] = [
            [.s("Month"), .s(monthKey)],
            [.s("Currency"), .s(currency)],
            [.s("Generated at"), .s(generatedFmt.string(from: generatedAt))],
            [],
            [.s("Budget (€)"), .s("Spent (€)"), .s("Remaining (€)"), .s("Daily Avg (€)"), .s("Spent %")],
            [
                .n(Double(budgetCents) / 100.0),
                .n(Double(summary.totalSpent) / 100.0),
                .n(Double(summary.remaining) / 100.0),
                .n(Double(summary.dailyAvg) / 100.0),
                .n(summary.spentRatio * 100.0)
            ],
            [],
            [.s("Transactions count"), .n(Double(transactions.count))],
            [.s("Categories used"), .n(Double(Set(transactions.map { $0.category }).count))]
        ]

        // Categories sheet (add % share + transaction count)
        var catRows: [[Cell]] = [[.s("Category"), .s("Transactions"), .s("Spent (€)"), .s("Share (%)")]]
        for r in categories {
            let share = totalSpentCents > 0 ? (Double(r.total) / Double(totalSpentCents) * 100.0) : 0
            catRows.append([
                .s(r.category.title),
                .n(Double(txCountByCategory[r.category] ?? 0)),
                .n(Double(r.total) / 100.0),
                .n(share)
            ])
        }

        // Category caps sheet (full budgeting context)
        var capRows: [[Cell]] = [[.s("Category"), .s("Cap (€)"), .s("Spent (€)"), .s("Remaining (€)"), .s("Used (%)"), .s("Transactions")]]
        for c in Category.allCases {
            let cap = categoryCapsCents[c] ?? 0
            let spent = spentByCategory[c] ?? 0
            let remaining = cap - spent
            let used = cap > 0 ? (Double(spent) / Double(cap) * 100.0) : 0
            let cnt = txCountByCategory[c] ?? 0
            capRows.append([
                .s(c.title),
                .n(Double(cap) / 100.0),
                .n(Double(spent) / 100.0),
                .n(Double(remaining) / 100.0),
                .n(used),
                .n(Double(cnt))
            ])
        }

        // Daily sheet (add weekday + cumulative + remaining)
        var dailyRows: [[Cell]] = [[.s("Date"), .s("Weekday"), .s("Spent (€)"), .s("Cumulative (€)"), .s("Remaining (€)")]]
        var cumulativeDayCents = 0
        for d in daily.sorted(by: { $0.day < $1.day }) {
            cumulativeDayCents += d.amount

            var comps = DateComponents()
            comps.year = y
            comps.month = m
            comps.day = d.day
            let date = cal.date(from: comps) ?? monthDate

            dailyRows.append([
                .s(String(format: "%04d-%02d-%02d", y, m, d.day)),
                .s(dayNameFmt.string(from: date)),
                .n(Double(d.amount) / 100.0),
                .n(Double(cumulativeDayCents) / 100.0),
                .n(Double(budgetCents - cumulativeDayCents) / 100.0)
            ])
        }

        // Transactions sheet (most detailed)
        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "yyyy-MM-dd"

        var txRows: [[Cell]] = [[
            .s("Date"),
            .s("Category"),
            .s("Note"),
            .s("Amount (€)"),
            .s("Amount (cents)"),
            .s("Running spent (€)"),
            .s("Remaining (€)"),
            .s("Transaction ID")
        ]]

        var runningCents = 0
        for t in transactions.sorted(by: { $0.date < $1.date }) {
            runningCents += t.amount
            txRows.append([
                .s(df.string(from: t.date)),
                .s(t.category.title),
                .s(t.note),
                .n(Double(t.amount) / 100.0),
                .n(Double(t.amount)),
                .n(Double(runningCents) / 100.0),
                .n(Double(budgetCents - runningCents) / 100.0),
                .s(t.id.uuidString)
            ])
        }

        let sheets = [
            (name: "Summary", rows: summaryRows),
            (name: "Categories", rows: catRows),
            (name: "Category caps", rows: capRows),
            (name: "Daily", rows: dailyRows),
            (name: "Transactions", rows: txRows)
        ]

        let sheetNames = sheets.map { $0.name }
        let sheetCount = sheets.count

        // Assemble all files required for a minimal XLSX
        var entries: [(String, Data)] = []

        entries.append(("[Content_Types].xml", Data(contentTypesXML(sheetCount: sheetCount).utf8)))
        entries.append(("_rels/.rels", Data(relsXML().utf8)))
        entries.append(("xl/workbook.xml", Data(workbookXML(sheetNames: sheetNames).utf8)))
        entries.append(("xl/_rels/workbook.xml.rels", Data(workbookRelsXML(sheetCount: sheetCount).utf8)))

        // Minimal styles (so Excel is happy)
        entries.append(("xl/styles.xml", Data(stylesXML().utf8)))

        for (idx, s) in sheets.enumerated() {
            let xml = worksheetXML(rows: s.rows)
            entries.append(("xl/worksheets/sheet\(idx + 1).xml", Data(xml.utf8)))
        }

        return zipXLSX(entries: entries)
    }

    private static func contentTypesXML(sheetCount: Int) -> String {
        let overrides = (1...sheetCount).map { i in
            "  <Override PartName=\"/xl/worksheets/sheet\(i).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
        }.joined(separator: "\n")

        return """
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">
  <Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>
  <Default Extension=\"xml\" ContentType=\"application/xml\"/>
  <Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>
  <Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>
\(overrides)
</Types>
"""
    }

    private static func stylesXML() -> String {
        return """
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">
  <fonts count=\"1\"><font/></fonts>
  <fills count=\"2\">
    <fill><patternFill patternType=\"none\"/></fill>
    <fill><patternFill patternType=\"gray125\"/></fill>
  </fills>
  <borders count=\"1\"><border/></borders>
  <cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>
  <cellXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/></cellXfs>
  <cellStyles count=\"1\"><cellStyle name=\"Normal\" xfId=\"0\" builtinId=\"0\"/></cellStyles>
</styleSheet>
"""
    }

private static func zipXLSX(entries: [(String, Data)]) -> Data {
    let fm = FileManager.default
    let dir = fm.temporaryDirectory.appendingPathComponent("balance.xlsx.tmp", isDirectory: true)
    try? fm.removeItem(at: dir)
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

    let zipURL = dir.appendingPathComponent("out.xlsx")
    try? fm.removeItem(at: zipURL)

    do {
        let archive = try Archive(url: zipURL, accessMode: .create)

        for (path, data) in entries {
            try archive.addEntry(
                with: path,
                type: .file,
                uncompressedSize: Int64(data.count),
                compressionMethod: .deflate,
                bufferSize: 16_384,
                progress: nil,
                provider: { position, size in
                    let start = Int(position)
                    let end = min(start + Int(size), data.count)
                    return data.subdata(in: start..<end)
                }
            )
        }

        return (try? Data(contentsOf: zipURL)) ?? Data()
    } catch {
        return Data()
    }
}

    // ---------- CSV (همین که داری می‌مونه)

    // MARK: - CSV (single file with sections)
    static func makeCSV(
        monthKey: String,
        currency: String,
        budgetCents: Int,
        summary: Analytics.MonthSummary,
        transactions: [Transaction],
        categories: [Analytics.CategoryRow],
        daily: [Analytics.DayPoint]
    ) -> String {
        func esc(_ s: String) -> String {
            let needsQuotes = s.contains(",") || s.contains("\n") || s.contains("\"")
            var out = s.replacingOccurrences(of: "\"", with: "\"\"")
            if needsQuotes { out = "\"" + out + "\"" }
            return out
        }

        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "yyyy-MM-dd"

        var lines: [String] = []

        // Summary
        lines.append("# Summary")
        lines.append("month,currency,budget_eur,spent_eur,remaining_eur,daily_avg_eur,spent_percent")
        lines.append("\(monthKey),\(currency),\(String(format: "%.2f", Double(budgetCents)/100.0)),\(String(format: "%.2f", Double(summary.totalSpent)/100.0)),\(String(format: "%.2f", Double(summary.remaining)/100.0)),\(String(format: "%.2f", Double(summary.dailyAvg)/100.0)),\(Int((summary.spentRatio*100.0).rounded()))%")
        lines.append("")

        // Categories
        lines.append("# Categories")
        lines.append("category,spent_eur")
        for r in categories {
            lines.append("\(esc(r.category.title)),\(String(format: "%.2f", Double(r.total)/100.0))")
        }
        lines.append("")

        // Daily
        lines.append("# Daily")
        lines.append("day,spent_eur")
        for d in daily.sorted(by: { $0.day < $1.day }) {
            lines.append("\(d.day),\(String(format: "%.2f", Double(d.amount)/100.0))")
        }
        lines.append("")

        // Transactions
        lines.append("# Transactions")
        lines.append("date,category,note,amount_eur")
        for t in transactions.sorted(by: { $0.date < $1.date }) {
            let dateStr = df.string(from: t.date)
            let cat = esc(t.category.title)
            let note = esc(t.note)
            let eur = String(format: "%.2f", Double(t.amount) / 100.0)
            lines.append("\(dateStr),\(cat),\(note),\(eur)")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - SpreadsheetML 2003 XML (Excel can open; extension is kept as .xlsx by caller)
    static func makeExcelXML(
        monthKey: String,
        currency: String,
        budgetCents: Int,
        summary: Analytics.MonthSummary,
        transactions: [Transaction],
        categories: [Analytics.CategoryRow],
        daily: [Analytics.DayPoint]
    ) -> String {
        func xesc(_ s: String) -> String {
            s.replacingOccurrences(of: "&", with: "&amp;")
             .replacingOccurrences(of: "<", with: "&lt;")
             .replacingOccurrences(of: ">", with: "&gt;")
             .replacingOccurrences(of: "\"", with: "&quot;")
             .replacingOccurrences(of: "'", with: "&apos;")
        }

        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "yyyy-MM-dd"

        func row(_ cells: [String], header: Bool = false) -> String {
            var out = "      <Row>\n"
            for c in cells {
                let style = header ? " ss:StyleID=\"sHeader\"" : ""
                out += "        <Cell\(style)><Data ss:Type=\"String\">\(xesc(c))</Data></Cell>\n"
            }
            out += "      </Row>\n"
            return out
        }

        func sheet(_ name: String, _ rows: [String]) -> String {
            var out = "  <Worksheet ss:Name=\"\(xesc(name))\">\n    <Table>\n"
            for r in rows { out += r }
            out += "    </Table>\n  </Worksheet>\n"
            return out
        }

        let summaryRows: [String] = [
            row(["Month", monthKey], header: true),
            row(["Currency", currency]),
            row([""], header: false),
            row(["Budget (€)", "Spent (€)", "Remaining (€)", "Daily Avg (€)", "Spent %"], header: true),
            row([
                String(format: "%.2f", Double(budgetCents)/100.0),
                String(format: "%.2f", Double(summary.totalSpent)/100.0),
                String(format: "%.2f", Double(summary.remaining)/100.0),
                String(format: "%.2f", Double(summary.dailyAvg)/100.0),
                String(format: "%.0f%%", summary.spentRatio*100.0)
            ])
        ]

        var catRows: [String] = [row(["Category", "Spent (€)"], header: true)]
        for r in categories {
            catRows.append(row([r.category.title, String(format: "%.2f", Double(r.total)/100.0)]))
        }

        var dayRows: [String] = [row(["Day", "Spent (€)"], header: true)]
        for d in daily.sorted(by: { $0.day < $1.day }) {
            dayRows.append(row(["\(d.day)", String(format: "%.2f", Double(d.amount)/100.0)]))
        }

        var txRows: [String] = [row(["Date", "Category", "Note", "Amount (€)"], header: true)]
        for t in transactions.sorted(by: { $0.date < $1.date }) {
            txRows.append(row([
                df.string(from: t.date),
                t.category.title,
                t.note,
                String(format: "%.2f", Double(t.amount)/100.0)
            ]))
        }

        let workbook = """
        <?xml version="1.0"?>
        <?mso-application progid="Excel.Sheet"?>
        <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
         xmlns:o="urn:schemas-microsoft-com:office:office"
         xmlns:x="urn:schemas-microsoft-com:office:excel"
         xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
          <Styles>
            <Style ss:ID="sHeader"><Font ss:Bold="1"/></Style>
          </Styles>
        """

        return workbook
            + sheet("Summary", summaryRows)
            + sheet("Categories", catRows)
            + sheet("Daily", dayRows)
            + sheet("Transactions", txRows)
            + "</Workbook>\n"
    }

    private static func relsXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
    }

    private static func workbookXML(sheetNames: [String]) -> String {
        let sheets = sheetNames.enumerated().map { idx, name in
            "<sheet name=\"\(xmlEsc(name))\" sheetId=\"\(idx+1)\" r:id=\"rId\(idx+1)\"/>"
        }.joined()

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
          xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>\(sheets)</sheets>
        </workbook>
        """
    }

    private static func workbookRelsXML(sheetCount: Int) -> String {
        let sheetRels = (1...sheetCount).map { i in
            "<Relationship Id=\"rId\(i)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet\(i).xml\"/>"
        }.joined(separator: "\n  ")

        let stylesRel = "<Relationship Id=\"rId\(sheetCount + 1)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>"

        return """
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">
  \(sheetRels)
  \(stylesRel)
</Relationships>
"""
    }
    
    private enum Cell {
        case s(String)   // string
        case n(Double)   // number
    }

    private static func worksheetXML(rows: [[Cell]]) -> String {
        func colRef(_ col: Int) -> String {
            var n = col
            var s = ""
            while n > 0 {
                let r = (n - 1) % 26
                s = String(UnicodeScalar(65 + r)!) + s
                n = (n - 1) / 26
            }
            return s
        }

        var xmlRows = ""
        for (rIdx, row) in rows.enumerated() {
            let rowNum = rIdx + 1
            var cells = ""
            for (cIdx, cell) in row.enumerated() {
                let ref = "\(colRef(cIdx + 1))\(rowNum)"
                switch cell {
                case .s(let v):
                    cells += "<c r=\"\(ref)\" t=\"inlineStr\"><is><t>\(xmlEsc(v))</t></is></c>"
                case .n(let v):
                    let s = String(format: "%.2f", v) // dot decimal
                    cells += "<c r=\"\(ref)\"><v>\(s)</v></c>"
                }
            }
            xmlRows += "<row r=\"\(rowNum)\">\(cells)</row>"
        }

        return """
<?xml version="1.0" encoding="UTF-8"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>\(xmlRows)</sheetData>
</worksheet>
"""
    }

    private static func centsToEuros(_ cents: Int) -> Double { Double(cents) / 100.0 }

    private static func xmlEsc(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: "&", with: "&amp;")
        out = out.replacingOccurrences(of: "<", with: "&lt;")
        out = out.replacingOccurrences(of: ">", with: "&gt;")
        out = out.replacingOccurrences(of: "\"", with: "&quot;")
        out = out.replacingOccurrences(of: "'", with: "&apos;")
        return out
    }
}



private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
    

private struct ImportTransactionsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var store: Store

    @State private var pickedURL: URL? = nil
    @State private var parsed: ParsedCSV? = nil
    @State private var statusText: String? = nil
    @State private var isPicking = false

    // Column mapping
    @State private var colDate: Int? = nil
    @State private var colAmount: Int? = nil
    @State private var colCategory: Int? = nil
    @State private var colNote: Int? = nil

    @State private var hasHeaderRow: Bool = true

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Import transactions from CSV")
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Recommended CSV columns (header row preferred):")
                                Text("date (required), amount (required, EUR), category (required), note (optional)")
                                Text("Note: If you import the same CSV again, Balance will only add transactions that aren’t already in the app (duplicates are skipped).")
                            }
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)

                            Button {
                                isPicking = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc")
                                    Text(pickedURL == nil ? "Choose CSV file" : pickedURL!.lastPathComponent)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(DS.PrimaryButton())

                            Text("Tip: If your file is .xlsx, export it as CSV in Excel, then import here.")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }

                    if let parsed {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Columns")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                Toggle("Header row", isOn: $hasHeaderRow)
                                    .tint(DS.Colors.positive)

                                columnPicker(title: "Date", columns: parsed.columns, selection: $colDate)
                                columnPicker(title: "Amount", columns: parsed.columns, selection: $colAmount)
                                columnPicker(title: "Category", columns: parsed.columns, selection: $colCategory)
                                columnPicker(title: "Note (optional)", columns: parsed.columns, selection: $colNote)

                                Divider().overlay(DS.Colors.grid)

                                Text("Preview")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(parsed.previewRows.prefix(10).indices, id: \.self) { i in
                                        let row = parsed.previewRows[i]
                                        Text(row.joined(separator: "  |  "))
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                            .lineLimit(1)
                                    }
                                }

                                Divider().overlay(DS.Colors.grid)

                                Button {
                                    importNow(parsed)
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Import into Balance")
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .disabled(colDate == nil || colAmount == nil || colCategory == nil)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if let statusText {
                        DS.Card {
                            Text(statusText)
                                .font(DS.Typography.caption)
                                .foregroundStyle(statusText.hasPrefix("Imported") ? DS.Colors.positive : DS.Colors.danger)
                        }
                        .transition(.opacity)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(DS.Colors.subtext)
            }
        }
        .sheet(isPresented: $isPicking) {
            CSVDocumentPicker { url in
                pickedURL = url
                parse(url: url)
            }
        }
        .onChange(of: hasHeaderRow) { _, _ in
            if let parsed { autoDetectMapping(parsed) }
        }
    }

    // MARK: UI helpers

    private func columnPicker(title: String, columns: [String], selection: Binding<Int?>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.subtext)

            Picker(title, selection: Binding(get: {
                selection.wrappedValue ?? -1
            }, set: { newValue in
                selection.wrappedValue = (newValue >= 0 ? newValue : nil)
            })) {
                Text("—").tag(-1)
                ForEach(columns.indices, id: \.self) { idx in
                    Text(columns[idx]).tag(idx)
                }
            }
            .pickerStyle(.menu)
            .tint(DS.Colors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Colors.grid, lineWidth: 1)
            )
        }
    }

    // MARK: Parsing / Mapping

    private func readCSVText(from url: URL) throws -> String {
        // DocumentPicker URLs may require security-scoped access
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)

        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .windowsCP1252, // Excel in many locales (e.g., €)
            .isoLatin1
        ]

        for enc in encodings {
            if let s = String(data: data, encoding: enc) {
                return s
            }
        }

        throw NSError(domain: "CSV", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported text encoding"])
    }

    private func parse(url: URL) {
        statusText = nil
        parsed = nil

        do {
            let text = try readCSVText(from: url)
            let table = CSV.parse(text)

            guard !table.isEmpty else {
                statusText = "CSV is empty."
                return
            }

            let header = table.first ?? []
            let rows = Array(table.dropFirst())

            let columns: [String]
            let previewRows: [[String]]

            if hasHeaderRow {
                columns = header.map { $0.isEmpty ? "(empty)" : $0 }
                previewRows = Array(rows.prefix(14))
            } else {
                let maxCols = table.map { $0.count }.max() ?? 0
                columns = (0..<maxCols).map { "Column \($0 + 1)" }
                previewRows = Array(table.prefix(14))
            }

            let parsedCSV = ParsedCSV(raw: table, columns: columns, previewRows: previewRows)
            parsed = parsedCSV
            autoDetectMapping(parsedCSV)

        } catch {
            statusText = "Could not read file. Export as CSV UTF-8 (or a standard CSV)."
        }
    }

    private func autoDetectMapping(_ parsed: ParsedCSV) {
        func norm(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        let names = parsed.columns.map(norm)

        func firstIndex(matching any: [String]) -> Int? {
            for a in any {
                if let idx = names.firstIndex(where: { $0 == a || $0.contains(a) }) { return idx }
            }
            return nil
        }

        colDate = firstIndex(matching: ["date", "day", "datum"])
        colAmount = firstIndex(matching: ["amount", "value", "spent", "cost", "eur", "€"])
        colCategory = firstIndex(matching: ["category", "cat", "type"])
        colNote = firstIndex(matching: ["note", "description", "desc", "memo"])
    }

    private func parseDate(_ s: String) -> Date? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        // 1) Try plain date formats (most common)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")

        let fmts = [
            "yyyy-MM-dd",
            "dd.MM.yyyy",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy/MM/dd"
        ]
        for f in fmts {
            df.dateFormat = f
            if let d = df.date(from: trimmed) { return d }
        }

        // 2) Try dates with time (Excel / Numbers often exports these)
        let fmtsWithTime = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]
        for f in fmtsWithTime {
            df.dateFormat = f
            if let d = df.date(from: trimmed) { return d }
        }

        // 3) Try ISO 8601 (with/without fractional seconds)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: trimmed) { return d }

        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]
        if let d = iso2.date(from: trimmed) { return d }

        return nil
    }

    private func mapCategory(_ s: String) -> Category {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.isEmpty { return .other }

        for c in Category.allCases {
            if c.title.lowercased() == t { return c }
            if c.rawValue.lowercased() == t { return c }
        }

        if t.contains("groc") { return .groceries }
        if t.contains("rent") { return .rent }
        if t.contains("bill") { return .bills }
        if t.contains("trans") || t.contains("uber") || t.contains("taxi") { return .transport }
        if t.contains("health") || t.contains("pharm") { return .health }
        if t.contains("edu") || t.contains("school") { return .education }
        if t.contains("dining") || t.contains("food") || t.contains("restaurant") { return .dining }
        if t.contains("shop") { return .shopping }
        if t.contains("ent") || t.contains("movie") || t.contains("game") { return .entertainment }
        return .other
    }

    private func importNow(_ parsed: ParsedCSV) {
        guard let dIdx = colDate, let aIdx = colAmount, let cIdx = colCategory else {
            statusText = "Please map Date, Amount, Category columns."
            return
        }

        let table = parsed.raw
        let dataRows: [[String]] = hasHeaderRow ? Array(table.dropFirst()) : table

        // Build a signature set for existing transactions so we can prevent re-importing
        // the same data even if the filename differs.
        func txSignature(date: Date, amountCents: Int, category: Category, note: String) -> String {
            let day = Calendar.current.startOfDay(for: date)
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd"
            let dayStr = df.string(from: day)
            let noteNorm = note.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(dayStr)|\(amountCents)|\(category.rawValue)|\(noteNorm)"
        }

        var existingSigs: Set<String> = []
        existingSigs.reserveCapacity(store.transactions.count)
        for t in store.transactions {
            existingSigs.insert(txSignature(date: t.date, amountCents: t.amount, category: t.category, note: t.note))
        }

        // First pass: validate + detect duplicates (against store and within the CSV)
        var newTransactions: [Transaction] = []
        newTransactions.reserveCapacity(max(0, dataRows.count))

        var newSigs: Set<String> = []
        var added = 0
        var skipped = 0
        var dupesFound = 0
        var importedMonths: Set<String> = []
        var latestImportedDate: Date? = nil

        for r in dataRows {
            func cell(_ idx: Int) -> String { idx < r.count ? r[idx] : "" }

            guard let date = parseDate(cell(dIdx)) else { skipped += 1; continue }

            let amountCents = DS.Format.cents(from: cell(aIdx))
            if amountCents <= 0 { skipped += 1; continue }

            let category = mapCategory(cell(cIdx))
            let note = (colNote == nil) ? "" : cell(colNote!)

            let sig = txSignature(date: date, amountCents: amountCents, category: category, note: note)

            // Duplicate against existing store OR repeated rows inside the CSV.
            if existingSigs.contains(sig) || newSigs.contains(sig) {
                dupesFound += 1
                continue
            }

            newSigs.insert(sig)
            importedMonths.insert(Store.monthKey(date))
            if let cur = latestImportedDate {
                if date > cur { latestImportedDate = date }
            } else {
                latestImportedDate = date
            }

            newTransactions.append(Transaction(amount: amountCents, date: date, category: category, note: note))
            added += 1
        }

        if added == 0 {
            if dupesFound > 0 {
                statusText = "Nothing new to import. \(dupesFound) duplicate transaction(s) detected and skipped."
            } else {
                statusText = "No rows imported. Check date format and amount values."
            }
            return
        }

        // Second pass: apply changes only after we know there are no duplicates.
        for t in newTransactions {
            store.add(t)
        }

        // Jump to a relevant month so the user can immediately see what was imported.
        // If multiple months exist in the CSV, jump to the latest imported month.
        if let latestImportedDate {
            store.selectedMonth = latestImportedDate
        } else if let anyKey = importedMonths.first {
            // Fallback: should rarely happen, but keep it safe.
            // Keep selectedMonth unchanged if we can't derive a date.
            _ = anyKey
        }

        store.save()
        Haptics.success()
        statusText = "Imported \(added) new transaction(s). Skipped \(skipped). Duplicates skipped: \(dupesFound)."
    }

    // MARK: Models

    private struct ParsedCSV {
        let raw: [[String]]
        let columns: [String]
        let previewRows: [[String]]
    }
}

// MARK: - CSV Document Picker

private struct CSVDocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [UTType.commaSeparatedText, UTType.plainText]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

// MARK: - CSV Parser

private enum CSV {
    static func parse(_ text: String) -> [[String]] {
        // Strip UTF-8 BOM if present (common with Excel/Numbers exports)
        let cleaned = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text

        // Normalize line endings so parsing is consistent:
        // - CRLF (\r\n)
        // - CR-only (\r)
        // - Unicode line separators (\u2028 / \u2029)
        let normalized = cleaned
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n")

        // Auto-detect delimiter: Excel in many EU locales uses ';' instead of ','
        let firstLine = normalized.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
        let commaCount = firstLine.filter { $0 == "," }.count
        let semiCount = firstLine.filter { $0 == ";" }.count
        let delimiter: Character = (semiCount > commaCount) ? ";" : ","

        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false

        func endField() {
            row.append(field)
            field = ""
        }

        func endRow() {
            rows.append(row)
            row = []
        }

        let chars = Array(normalized)
        var i = 0
        while i < chars.count {
            let ch = chars[i]

            if inQuotes {
                if ch == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(ch)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                } else if ch == delimiter {
                    endField()
                } else if ch == "\n" {
                    endField()
                    endRow()
                } else {
                    field.append(ch)
                }
            }

            i += 1
        }

        if !field.isEmpty || !row.isEmpty {
            endField()
            endRow()
        }

        return rows.map { $0.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
    }
}


