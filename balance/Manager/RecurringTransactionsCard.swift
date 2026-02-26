// ==========================================
// Recurring Transactions Card
// Card برای نمایش در Insights
// ==========================================

import SwiftUI

struct RecurringTransactionsCard: View {
    @Binding var store: Store
    @State private var showRecurringView = false
    
    var activeCount: Int {
        store.recurringTransactions.filter { $0.isActive }.count
    }
    
    var monthlyTotal: Int {
        store.recurringTransactions
            .filter { $0.isActive && $0.frequency == .monthly }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        Button {
            showRecurringView = true
            Haptics.medium()
        } label: {
            LiquidGlassCard {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse.byLayer, options: .repeating)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Recurring Transactions")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(DS.Colors.text)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DS.Colors.subtext)
                        }
                        
                        if activeCount > 0 {
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.green)
                                    Text("\(activeCount) active")
                                        .font(.system(size: 13))
                                }
                                
                                if monthlyTotal > 0 {
                                    Text("•")
                                        .font(.system(size: 13))
                                    
                                    Text("€\(DS.Format.currency(monthlyTotal))/mo")
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .foregroundStyle(DS.Colors.subtext)
                        } else {
                            Text("Automate your regular expenses")
                                .font(.system(size: 13))
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showRecurringView) {
            RecurringTransactionsView(store: $store)
        }
    }
}

// Usage in InsightsView:
// بعد از Quick Actions card اضافه کن:
//
// RecurringTransactionsCard(store: $store)
