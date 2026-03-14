import SwiftUI

// MARK: - Goals Overview View

struct GoalsOverviewView: View {
    
    @StateObject private var goalManager = GoalManager.shared
    @State private var showCreateGoal = false
    @State private var goalToEdit: Goal?
    @State private var showCompleted = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Summary
                summaryCard
                
                // Active Goals
                if !goalManager.activeGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Active Goals")
                            .font(DS.Typography.section)
                            .foregroundStyle(DS.Colors.text)
                            .padding(.horizontal, 4)
                        
                        ForEach(goalManager.activeGoals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalCardView(goal: goal)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button { goalToEdit = goal } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    Task { _ = await goalManager.deleteGoal(goal) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // Completed
                if !goalManager.completedGoals.isEmpty {
                    DisclosureGroup(
                        isExpanded: $showCompleted,
                        content: {
                            VStack(spacing: 8) {
                                ForEach(goalManager.completedGoals) { goal in
                                    NavigationLink(destination: GoalDetailView(goal: goal)) {
                                        GoalCardView(goal: goal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 8)
                        },
                        label: {
                            Text("Completed (\(goalManager.completedGoals.count))")
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    )
                    .tint(DS.Colors.subtext)
                }
                
                // Empty State
                if goalManager.goals.isEmpty && !goalManager.isLoading {
                    emptyState
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(DS.Colors.bg.ignoresSafeArea())
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateGoal = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(DS.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showCreateGoal) {
            CreateEditGoalView(mode: .create)
        }
        .sheet(item: $goalToEdit) { goal in
            CreateEditGoalView(mode: .edit(goal))
        }
        .task {
            await goalManager.fetchGoals()
        }
        .refreshable {
            await goalManager.fetchGoals()
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        DS.Card {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Saved")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                        Text(DS.Format.money(goalManager.totalSaved))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Colors.text)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Target")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                        Text(DS.Format.money(goalManager.totalTarget))
                            .font(DS.Typography.number)
                            .foregroundStyle(DS.Colors.subtext)
                    }
                }
                
                // Overall progress
                let overallProgress = goalManager.totalTarget > 0
                    ? Double(goalManager.totalSaved) / Double(goalManager.totalTarget)
                    : 0
                
                GoalProgressBar(progress: overallProgress, height: 6)
                
                HStack {
                    Text("\(goalManager.activeGoals.count) active")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                    Spacer()
                    Text("\(Int(overallProgress * 100))%")
                        .font(DS.Typography.caption.weight(.semibold))
                        .foregroundStyle(DS.Colors.accent)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "target")
                .font(.system(size: 44))
                .foregroundStyle(DS.Colors.subtext.opacity(0.4))
            
            Text("No Goals Yet")
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.text)
            
            Text("Set savings goals to track your progress toward things that matter.")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.subtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showCreateGoal = true
            } label: {
                Label("Create Goal", systemImage: "plus")
                    .font(DS.Typography.body.weight(.semibold))
            }
            .buttonStyle(DS.ColoredButton())
            .padding(.horizontal, 60)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Goal Card View

struct GoalCardView: View {
    let goal: Goal
    
    var body: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    // Icon
                    Image(systemName: goal.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                        .frame(width: 32, height: 32)
                        .background(DS.Colors.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.name)
                            .font(DS.Typography.body.weight(.semibold))
                            .foregroundStyle(DS.Colors.text)
                        
                        Text(goal.type.displayName)
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                    }
                    
                    Spacer()
                    
                    // Status
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(DS.Format.money(goal.currentAmount))
                            .font(DS.Typography.number)
                            .foregroundStyle(DS.Colors.text)
                        
                        Text("of \(DS.Format.money(goal.targetAmount))")
                            .font(.system(size: 10))
                            .foregroundStyle(DS.Colors.subtext)
                    }
                }
                
                // Progress bar
                GoalProgressBar(progress: goal.progress, height: 5)
                
                // Bottom row
                HStack {
                    Text("\(goal.progressPercent)%")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.Colors.accent)
                    
                    Spacer()
                    
                    if let date = goal.targetDate {
                        Text(date, format: .dateTime.month(.abbreviated).day().year())
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Colors.subtext)
                    }
                    
                    if goal.isCompleted {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DS.Colors.positive)
                    } else {
                        Text(goal.trackingStatus.label)
                            .font(.system(size: 11))
                            .foregroundStyle(statusColor(goal.trackingStatus))
                    }
                }
            }
        }
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

// MARK: - Reusable Progress Bar

struct GoalProgressBar: View {
    let progress: Double
    var height: CGFloat = 5
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(DS.Colors.surface2)
                    .frame(height: height)
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(DS.Colors.accent)
                    .frame(width: geo.size.width * min(progress, 1.0), height: height)
            }
        }
        .frame(height: height)
    }
}
