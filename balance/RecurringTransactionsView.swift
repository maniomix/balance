import SwiftUI

// MARK: - Recurring Transactions View

struct RecurringTransactionsView: View {
    @Binding var store: Store
    @State private var showAddSheet = false
    @State private var editingRecurring: RecurringTransaction?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if store.recurringTransactions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.recurringTransactions) { recurring in
                            RecurringCard(recurring: recurring) {
                                editingRecurring = recurring
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(DS.Colors.bg.ignoresSafeArea())
            .navigationTitle(L10n.t("recurring.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DS.Colors.accent)
                    }
                }
                
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
            .sheet(isPresented: $showAddSheet) {
                AddRecurringSheet(store: $store)
            }
            .sheet(item: $editingRecurring) { recurring in
                EditRecurringSheet(store: $store, recurring: recurring)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "repeat.circle")
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(DS.Colors.subtext.opacity(0.3))
            
            Text(L10n.t("recurring.empty"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(DS.Colors.text)
            
            Text(L10n.t("recurring.empty_desc"))
                .font(.system(size: 14))
                .foregroundStyle(DS.Colors.subtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Haptics.light()
                showAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text(L10n.t("recurring.add"))
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(DS.Colors.accent)
                .cornerRadius(12)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recurring Card

private struct RecurringCard: View {
    let recurring: RecurringTransaction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            DS.Card {
                VStack(spacing: 12) {
                    HStack {
                        // Icon
                        Circle()
                            .fill(recurring.type == .income ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: recurring.category.icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(recurring.type == .income ? Color.green : Color.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recurring.note.isEmpty ? recurring.category.title : recurring.note)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(DS.Colors.text)
                            
                            HStack(spacing: 6) {
                                Image(systemName: recurring.frequency.icon)
                                    .font(.system(size: 11))
                                Text(recurring.frequency.displayName)
                                    .font(.system(size: 13))
                            }
                            .foregroundStyle(DS.Colors.subtext)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(DS.Format.money(recurring.amount))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(recurring.type == .income ? Color.green : DS.Colors.text)
                            
                            if !recurring.isActive {
                                Text("Paused")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    // Next occurrence
                    if recurring.isActive, let next = recurring.nextOccurrence(after: Date()) {
                        Divider()
                        
                        HStack {
                            Text(L10n.t("recurring.next_occurrence"))
                                .font(.system(size: 12))
                                .foregroundStyle(DS.Colors.subtext)
                            
                            Spacer()
                            
                            Text(formatDate(next))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(DS.Colors.text)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Add Recurring Sheet

private struct AddRecurringSheet: View {
    @Binding var store: Store
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var selectedCategory: Category = .food
    @State private var note: String = ""
    @State private var selectedPaymentMethod: PaymentMethod = .card
    @State private var selectedType: TransactionType = .expense
    @State private var selectedFrequency: RecurringFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Type picker
                    Picker("Type", selection: $selectedType) {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                            Text("Expense")
                        }
                        .tag(TransactionType.expense)
                        
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Income")
                        }
                        .tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    
                    // Amount
                    HStack {
                        Text("€")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DS.Colors.subtext)
                        
                        TextField("0.00", text: $amount)
                            .font(.system(size: 18, weight: .semibold))
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Details") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.title)
                            }
                            .tag(cat)
                        }
                    }
                    
                    TextField("Note", text: $note)
                    
                    Picker("Payment", selection: $selectedPaymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            HStack {
                                Image(systemName: method.icon)
                                Text(method.displayName)
                            }
                            .tag(method)
                        }
                    }
                }
                
                Section("Frequency") {
                    Picker(L10n.t("recurring.frequency"), selection: $selectedFrequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                            HStack {
                                Image(systemName: freq.icon)
                                Text(freq.displayName)
                            }
                            .tag(freq)
                        }
                    }
                    
                    DatePicker(L10n.t("recurring.start_date"), selection: $startDate, displayedComponents: .date)
                    
                    Toggle("Has End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker(L10n.t("recurring.end_date"), selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(L10n.t("recurring.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.save")) {
                        saveRecurring()
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
    
    private func saveRecurring() {
        guard let amountDouble = Double(amount.replacingOccurrences(of: ",", with: ".")),
              amountDouble > 0 else { return }
        
        let amountCents = Int(amountDouble * 100)
        
        let recurring = RecurringTransaction(
            amount: amountCents,
            category: selectedCategory,
            note: note,
            paymentMethod: selectedPaymentMethod,
            type: selectedType,
            frequency: selectedFrequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil
        )
        
        store.recurringTransactions.append(recurring)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Edit Recurring Sheet

private struct EditRecurringSheet: View {
    @Binding var store: Store
    let recurring: RecurringTransaction
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var isActive: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("€")
                            .font(.system(size: 18, weight: .semibold))
                        TextField("0.00", text: $amount)
                            .font(.system(size: 18, weight: .semibold))
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Note", text: $note)
                }
                
                Section {
                    Toggle(L10n.t("recurring.active"), isOn: $isActive)
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteRecurring()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(L10n.t("common.delete"))
                        }
                    }
                }
            }
            .navigationTitle(L10n.t("recurring.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.save")) {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                amount = String(format: "%.2f", Double(recurring.amount) / 100.0)
                note = recurring.note
                isActive = recurring.isActive
            }
        }
    }
    
    private func saveChanges() {
        guard let index = store.recurringTransactions.firstIndex(where: { $0.id == recurring.id }) else { return }
        
        if let amountDouble = Double(amount.replacingOccurrences(of: ",", with: ".")),
           amountDouble > 0 {
            let amountCents = Int(amountDouble * 100)
            store.recurringTransactions[index].amount = amountCents
        }
        
        store.recurringTransactions[index].note = note
        store.recurringTransactions[index].isActive = isActive
        
        Haptics.success()
        dismiss()
    }
    
    private func deleteRecurring() {
        store.recurringTransactions.removeAll { $0.id == recurring.id }
        Haptics.transactionDeleted()
        dismiss()
    }
}
