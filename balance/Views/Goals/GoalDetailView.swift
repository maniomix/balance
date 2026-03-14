import SwiftUI

// MARK: - Goal Detail View

struct GoalDetailView: View {
    
    let goal: Goal
    
    @StateObject private var goalManager = GoalManager.shared
    @State private var contributions: [GoalContribution] = []
    @State private var averageMonthly: Int = 0
    @State private var showAddContribution = false
    @State private var contributionAmountText = ""
    @State private var contributionNote = ""
    @State private var showEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                progressCard
                projectionCard
                contributionSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(DS.Colors.bg.ignoresSafeArea())
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditSheet = true }
                    .foregroundStyle(DS.Colors.accent)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            CreateEditGoalView(mode: .edit(goal))
        }
        .alert("Add Contribution", isPresented: $showAddContribution) {
            TextField("Amount", text: $contributionAmountText)
                .keyboardType(.decimalPad)
            TextField("Note (optional)", text: $contributionNote)
            Button("Cancel", role: .cancel) {
                contributionAmountText = ""
                contributionNote = ""
            }
            Button("Add") {
                Task { await addContribution() }
            }
        } message: {
            Text("Enter the amount to add toward \(goal.name).")
        }
        .task { await loadData() }
    }
    
    // MARK: - Progress Card
    
    private var progressCard: some View {
        DS.Card {
            VStack(spacing: 16) {
                // Icon + amount
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(DS.Colors.accent)
                    .frame(width: 50, height: 50)
                    .background(DS.Colors.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                Text(DS.Format.money(goal.currentAmount))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Colors.text)
                
                Text("of \(DS.Format.money(goal.targetAmount))")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.subtext)
                
                // Progress bar
                GoalProgressBar(progress: goal.progress, height: 8)
                
                HStack {
                    Text("\(goal.progressPercent)%")
                        .font(DS.Typography.caption.weight(.semibold))
                        .foregroundStyle(DS.Colors.accent)
                    
                    Spacer()
                    
                    Text("\(DS.Format.money(goal.remainingAmount)) remaining")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                }
                
                // Status badge
                if !goal.isCompleted {
                    let status = goal.trackingStatus
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor(status))
                            .frame(width: 6, height: 6)
                        Text(status.label)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(statusColor(status))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(status).opacity(0.1), in: Capsule())
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Goal completed")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Colors.positive)
                }
                
                // Add contribution button
                if !goal.isCompleted {
                    Button {
                        showAddContribution = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Contribution")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DS.PrimaryButton())
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Projection Card
    
    private var projectionCard: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Projection")
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)
                
                VStack(spacing: 0) {
                    // Required monthly
                    if let required = goal.requiredMonthlySaving {
                        projectionRow(
                            "Required monthly",
                            DS.Format.money(required)
                        )
                        Divider().padding(.vertical, 6)
                    }
                    
                    // Average monthly
                    projectionRow(
                        "Avg. monthly saving",
                        averageMonthly > 0 ? DS.Format.money(averageMonthly) : "—"
                    )
                    
                    // Estimated completion
                    if let est = goal.estimatedCompletion(averageMonthly: averageMonthly) {
                        Divider().padding(.vertical, 6)
                        projectionRow(
                            "Est. completion",
                            est.formatted(.dateTime.month(.abbreviated).year())
                        )
                    }
                    
                    // Target date
                    if let target = goal.targetDate {
                        Divider().padding(.vertical, 6)
                        projectionRow(
                            "Target date",
                            target.formatted(.dateTime.month(.abbreviated).day().year())
                        )
                    }
                }
                
                // Notes
                if let notes = goal.notes, !notes.isEmpty {
                    Divider().padding(.vertical, 6)
                    Text(notes)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.subtext)
                }
            }
        }
    }
    
    private func projectionRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.subtext)
            Spacer()
            Text(value)
                .font(DS.Typography.body.weight(.semibold))
                .foregroundStyle(DS.Colors.text)
        }
    }
    
    // MARK: - Contributions Section
    
    private var contributionSection: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Contributions")
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)
                
                if contributions.isEmpty {
                    Text("No contributions yet")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.subtext)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    ForEach(contributions.prefix(20)) { c in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(DS.Typography.body.weight(.medium))
                                    .foregroundStyle(DS.Colors.text)
                                
                                if let note = c.note, !note.isEmpty {
                                    Text(note)
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Text("+ \(DS.Format.money(c.amount))")
                                .font(DS.Typography.number)
                                .foregroundStyle(DS.Colors.positive)
                        }
                        
                        if c.id != contributions.prefix(20).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Data
    
    private func loadData() async {
        contributions = await goalManager.fetchContributions(for: goal)
        averageMonthly = await goalManager.averageMonthlyContribution(for: goal)
    }
    
    private func addContribution() async {
        let cents = DS.Format.cents(from: contributionAmountText)
        guard cents > 0 else { return }
        _ = await goalManager.addContribution(
            to: goal,
            amount: cents,
            note: contributionNote.isEmpty ? nil : contributionNote
        )
        contributionAmountText = ""
        contributionNote = ""
        await loadData()
    }
    
    private func statusColor(_ status: Goal.TrackingStatus) -> Color {
        switch status {
        case .ahead: return DS.Colors.positive
        case .onTrack: return DS.Colors.accent
        case .behind: return DS.Colors.danger
        case .completed: return DS.Colors.positive
        case .noTarget: return DS.Colors.subtext
        }
    }
}
