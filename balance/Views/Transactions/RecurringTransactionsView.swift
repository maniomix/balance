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
                .foregroundStyle(.black)  // ← متن سیاه
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white)  // ← پس‌زمینه سفید
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
    @State private var selectedCategory: Category = .groceries
    @State private var note: String = ""
    @State private var selectedPaymentMethod: PaymentMethod = .card
    @State private var selectedType: TransactionType = .expense
    @State private var selectedFrequency: RecurringFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Type Toggle
                        DS.Card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Type")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                HStack(spacing: 8) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedType = .expense
                                        }
                                        Haptics.selection()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 14))
                                            Text("Expense")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundStyle(selectedType == .expense ? .white : DS.Colors.text)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedType == .expense ?
                                            Color.red : DS.Colors.surface2,
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedType = .income
                                        }
                                        Haptics.selection()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 14))
                                            Text("Income")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundStyle(selectedType == .income ? .white : DS.Colors.text)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedType == .income ?
                                            Color.green : DS.Colors.surface2,
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Amount
                        DS.Card {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Amount")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                HStack {
                                    Text("€")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(DS.Colors.text)
                                    
                                    TextField("0.00", text: $amount)
                                        .font(.system(size: 18, weight: .semibold))
                                        .keyboardType(.decimalPad)
                                }
                            }
                        }
                        
                        // Details
                        DS.Card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Details")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)
                                
                                Divider()
                                
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(Category.allCases, id: \.self) { cat in
                                        HStack {
                                            Image(systemName: cat.icon)
                                            Text(cat.title)
                                        }
                                        .tag(cat)
                                    }
                                }
                                .labelsHidden()
                                
                                Divider()
                                
                                TextField("Note", text: $note)
                                    .font(DS.Typography.body)
                                
                                Divider()
                                
                                Picker("Payment", selection: $selectedPaymentMethod) {
                                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                                        HStack {
                                            Image(systemName: method.icon)
                                            Text(method.displayName)
                                        }
                                        .tag(method)
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                        
                        // Frequency
                        DS.Card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Frequency")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)
                                
                                Divider()
                                
                                Picker(L10n.t("recurring.frequency"), selection: $selectedFrequency) {
                                    ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                        HStack {
                                            Image(systemName: freq.icon)
                                            Text(freq.displayName)
                                        }
                                        .tag(freq)
                                    }
                                }
                                .labelsHidden()
                                
                                Divider()
                                
                                DatePicker(L10n.t("recurring.start_date"), selection: $startDate, displayedComponents: .date)
                                
                                Divider()
                                
                                HStack {
                                    Text("Has End Date")
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Toggle("", isOn: $hasEndDate)
                                        .labelsHidden()
                                }
                                
                                if hasEndDate {
                                    Divider()
                                    DatePicker(L10n.t("recurring.end_date"), selection: $endDate, displayedComponents: .date)
                                }
                            }
                        }
                        
                        // Save Button
                        Button {
                            saveRecurring()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text(L10n.t("common.save"))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)  // ← متن سیاه
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)  // ← پس‌زمینه سفید
                            .cornerRadius(12)
                        }
                        .disabled(amount.isEmpty)
                        .opacity(amount.isEmpty ? 0.5 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.t("recurring.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(DS.Colors.subtext)
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
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Amount & Note
                        DS.Card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Amount")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                HStack {
                                    Text("€")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(DS.Colors.text)
                                    TextField("0.00", text: $amount)
                                        .font(.system(size: 18, weight: .semibold))
                                        .keyboardType(.decimalPad)
                                }
                                
                                Divider()
                                
                                Text("Note")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                TextField("Note", text: $note)
                                    .font(DS.Typography.body)
                            }
                        }
                        
                        // Active Toggle
                        DS.Card {
                            HStack {
                                Text(L10n.t("recurring.active"))
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.text)
                                Spacer()
                                Toggle("", isOn: $isActive)
                                    .labelsHidden()
                            }
                        }
                        
                        // Save Button
                        Button {
                            saveChanges()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text(L10n.t("common.save"))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)  // ← متن سیاه
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)  // ← پس‌زمینه سفید
                            .cornerRadius(12)
                        }
                        
                        // Delete Button
                        Button(role: .destructive) {
                            deleteRecurring()
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text(L10n.t("common.delete"))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.t("recurring.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(DS.Colors.subtext)
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
