import SwiftUI

// MARK: - Goals Dashboard Card

/// Compact goals summary card for the main Dashboard.
/// Shows top active goals with progress. Taps into full GoalsOverviewView.
struct GoalsDashboardCard: View {
    
    @StateObject private var goalManager = GoalManager.shared
    
    var body: some View {
        if !goalManager.goals.isEmpty {
            NavigationLink(destination: GoalsOverviewView()) {
                DS.Card {
                    VStack(alignment: .leading, spacing: 10) {
                        // Header
                        HStack {
                            HStack(spacing: 5) {
                                Image(systemName: "target")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.Colors.accent)
                                Text("Goals")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                            
                            Spacer()
                            
                            Text("\(goalManager.activeGoals.count) active")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(DS.Colors.subtext)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(DS.Colors.subtext.opacity(0.4))
                        }
                        
                        // Top 3 goals
                        ForEach(goalManager.activeGoals.prefix(3)) { goal in
                            HStack(spacing: 10) {
                                Image(systemName: goal.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(DS.Colors.accent)
                                    .frame(width: 24, height: 24)
                                    .background(DS.Colors.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(goal.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(DS.Colors.text)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Text("\(goal.progressPercent)%")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundStyle(DS.Colors.accent)
                                    }
                                    
                                    GoalProgressBar(progress: goal.progress, height: 3)
                                }
                            }
                        }
                        
                        // Upcoming deadline warning
                        if let next = goalManager.upcomingDeadlines.first,
                           let date = next.targetDate {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text("\(next.name) due \(date, format: .dateTime.month(.abbreviated).day())")
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(DS.Colors.warning)
                            .padding(.top, 2)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .task {
                if goalManager.goals.isEmpty {
                    await goalManager.fetchGoals()
                }
            }
        }
    }
}
