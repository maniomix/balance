import Foundation

// MARK: - Recurring Transaction Manager

struct RecurringTransactionManager {
    
    /// Check and generate recurring transactions for today
    static func processRecurringTransactions(store: inout Store) {
        let today = Date()
        
        for index in store.recurringTransactions.indices {
            var recurring = store.recurringTransactions[index]
            
            // Skip if not active or already processed today
            guard recurring.isActive else { continue }
            guard recurring.shouldGenerateForDate(today) else { continue }
            
            // Generate transaction
            let transaction = Transaction(
                amount: recurring.amount,
                date: today,
                category: recurring.category,
                note: recurring.note.isEmpty ? "\(L10n.t("recurring.auto_generated")) - \(recurring.frequency.displayName)" : recurring.note,
                paymentMethod: recurring.paymentMethod,
                type: recurring.type
            )
            
            store.add(transaction)
            
            // Update last generated date
            store.recurringTransactions[index].lastGenerated = today
        }
    }
    
    /// Check if any recurring transactions need to be generated
    static func hasRecurringTransactionsToGenerate(store: Store) -> Bool {
        let today = Date()
        
        for recurring in store.recurringTransactions {
            if recurring.isActive && recurring.shouldGenerateForDate(today) {
                return true
            }
        }
        
        return false
    }
    
    /// Get upcoming recurring transactions for the next 7 days
    static func upcomingRecurringTransactions(store: Store, days: Int = 7) -> [(date: Date, recurring: RecurringTransaction)] {
        let calendar = Calendar.current
        var result: [(Date, RecurringTransaction)] = []
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            
            for recurring in store.recurringTransactions where recurring.isActive {
                if recurring.shouldGenerateForDate(date) {
                    result.append((date, recurring))
                }
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    /// Calculate total recurring expenses per month
    static func monthlyRecurringTotal(store: Store) -> (income: Int, expense: Int) {
        var income = 0
        var expense = 0
        
        for recurring in store.recurringTransactions where recurring.isActive {
            let monthlyAmount: Int
            
            switch recurring.frequency {
            case .daily:
                monthlyAmount = recurring.amount * 30
            case .weekly:
                monthlyAmount = recurring.amount * 4
            case .monthly:
                monthlyAmount = recurring.amount
            case .yearly:
                monthlyAmount = recurring.amount / 12
            }
            
            if recurring.type == .income {
                income += monthlyAmount
            } else {
                expense += monthlyAmount
            }
        }
        
        return (income, expense)
    }
}
