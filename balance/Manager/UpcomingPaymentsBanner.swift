// ==========================================
// Upcoming Payments Banner
// نمایش Recurring های نزدیک در Transactions
// ==========================================

import SwiftUI

struct UpcomingPaymentsBanner: View {
    @Binding var store: Store
    @State private var showRecurringView = false
    
    // Get next 3 upcoming recurring payments
    var upcomingPayments: [(RecurringTransaction, Date)] {
        let calendar = Calendar.current
        let now = Date()
        
        var upcoming: [(RecurringTransaction, Date)] = []
        
        for recurring in store.recurringTransactions.filter({ $0.isActive }) {
            if let nextDate = recurring.nextOccurrence(from: now) {
                // Only show if within next 7 days
                if let daysDiff = calendar.dateComponents([.day], from: now, to: nextDate).day,
                   daysDiff <= 7 {
                    upcoming.append((recurring, nextDate))
                }
            }
        }
        
        // Sort by date and take first 3
        return upcoming
            .sorted { $0.1 < $1.1 }
            .prefix(3)
            .map { $0 }
    }
    
    var totalUpcoming: Int {
        upcomingPayments.reduce(0) { $0 + $1.0.amount }
    }
    
    var body: some View {
        if !upcomingPayments.isEmpty {
            Button {
                showRecurringView = true
                Haptics.light()
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(DS.Colors.surface2)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DS.Colors.text)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Upcoming Payments")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DS.Colors.text)
                            
                            Spacer()
                            
                            Text("€\(DS.Format.currency(totalUpcoming))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(DS.Colors.text)
                        }
                        
                        Text("\(upcomingPayments.count) payment\(upcomingPayments.count > 1 ? "s" : "") in the next 7 days")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Colors.subtext)
                    }
                    
                    // Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.Colors.subtext)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DS.Colors.surface2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(DS.Colors.grid, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .sheet(isPresented: $showRecurringView) {
                UpcomingPaymentsSheet(store: $store, upcomingPayments: upcomingPayments)
            }
        }
    }
}

// MARK: - Upcoming Payments Detail Sheet

struct UpcomingPaymentsSheet: View {
    @Binding var store: Store
    @Environment(\.dismiss) private var dismiss
    let upcomingPayments: [(RecurringTransaction, Date)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Summary card
                        summaryCard
                        
                        // Payment list
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next 7 Days")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(DS.Colors.text)
                                .padding(.horizontal)
                            
                            ForEach(upcomingPayments, id: \.0.id) { payment in
                                UpcomingPaymentRow(
                                    recurring: payment.0,
                                    nextDate: payment.1
                                )
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Upcoming Payments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Due")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.subtext)
                    
                    let total = upcomingPayments.reduce(0) { $0 + $1.0.amount }
                    Text("€\(DS.Format.currency(total))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(DS.Colors.text)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(DS.Colors.surface2)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 28))
                        .foregroundStyle(DS.Colors.text)
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                StatItem(
                    count: upcomingPayments.count,
                    label: "Payments",
                    color: .blue
                )
                
                let days = daysUntilNext()
                StatItem(
                    count: days,
                    label: days == 1 ? "Day" : "Days",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DS.Colors.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(DS.Colors.grid, lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    private func daysUntilNext() -> Int {
        guard let firstDate = upcomingPayments.first?.1 else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: firstDate).day ?? 0
        return max(0, days)
    }
}

// MARK: - Upcoming Payment Row

struct UpcomingPaymentRow: View {
    let recurring: RecurringTransaction
    let nextDate: Date
    
    private var daysUntil: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
        return max(0, days)
    }
    
    private var dateText: String {
        let formatter = DateFormatter()
        
        if daysUntil == 0 {
            return "Today"
        } else if daysUntil == 1 {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: nextDate)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(recurring.category.tint.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: recurring.category.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(recurring.category.tint)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(recurring.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Colors.text)
                
                HStack(spacing: 8) {
                    // Date badge
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(dateText)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(daysUntil == 0 ? Color.orange.opacity(0.2) : DS.Colors.surface2)
                    )
                    .foregroundStyle(daysUntil == 0 ? .orange : DS.Colors.subtext)
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.subtext)
                    
                    Text(recurring.frequency.displayName)
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.subtext)
                }
            }
            
            Spacer()
            
            // Amount
            Text("€\(DS.Format.currency(recurring.amount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DS.Colors.text)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DS.Colors.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(DS.Colors.grid, lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Usage in TransactionsView
/*
در TransactionsView، بعد از header و قبل از لیست transactions:

VStack(spacing: 0) {
    // Header
    TransactionsHeader(...)
    
    // ✅ Upcoming Payments Banner
    UpcomingPaymentsBanner(store: $store)
    
    // Transactions list
    ScrollView {
        ...
    }
}
*/
