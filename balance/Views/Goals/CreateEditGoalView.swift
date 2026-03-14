import SwiftUI

// MARK: - Create/Edit Goal View

struct CreateEditGoalView: View {
    
    enum Mode: Identifiable {
        case create
        case edit(Goal)
        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let g): return g.id.uuidString
            }
        }
    }
    
    let mode: Mode
    
    @StateObject private var goalManager = GoalManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var goalType: GoalType = .custom
    @State private var targetAmountText = ""
    @State private var currentAmountText = ""
    @State private var hasTargetDate = false
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    
    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    private var existing: Goal? {
        if case .edit(let g) = mode { return g }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Goal Name", text: $name)
                    
                    Picker("Type", selection: $goalType) {
                        ForEach(GoalType.allCases) { type in
                            Label(type.displayName, systemImage: type.defaultIcon)
                                .tag(type)
                        }
                    }
                } header: {
                    Text("Goal")
                }
                
                Section {
                    HStack {
                        Text(DS.Format.currencySymbol())
                            .foregroundStyle(DS.Colors.subtext)
                        TextField("Target Amount", text: $targetAmountText)
                            .keyboardType(.decimalPad)
                    }
                    
                    if isEditing {
                        HStack {
                            Text(DS.Format.currencySymbol())
                                .foregroundStyle(DS.Colors.subtext)
                            TextField("Current Amount", text: $currentAmountText)
                                .keyboardType(.decimalPad)
                        }
                    }
                } header: {
                    Text("Amount")
                }
                
                Section {
                    Toggle("Set Target Date", isOn: $hasTargetDate)
                        .tint(DS.Colors.accent)
                    
                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Timeline")
                }
                
                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
                
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Goal")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Create") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || targetAmountText.isEmpty || isSaving)
                }
            }
            .alert("Delete Goal", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        if let g = existing {
                            _ = await goalManager.deleteGoal(g)
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("This will permanently delete this goal and all contributions.")
            }
            .onAppear { loadExisting() }
        }
    }
    
    // MARK: - Helpers
    
    private func loadExisting() {
        guard let g = existing else { return }
        name = g.name
        goalType = g.type
        targetAmountText = DS.Format.currency(g.targetAmount)
        currentAmountText = DS.Format.currency(g.currentAmount)
        notes = g.notes ?? ""
        if let d = g.targetDate {
            hasTargetDate = true
            targetDate = d
        }
    }
    
    private func save() async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        isSaving = true
        
        let target = DS.Format.cents(from: targetAmountText)
        let current = DS.Format.cents(from: currentAmountText)
        
        if var g = existing {
            g.name = name
            g.type = goalType
            g.targetAmount = target
            g.currentAmount = current
            g.icon = goalType.defaultIcon
            g.colorToken = goalType.defaultColor
            g.targetDate = hasTargetDate ? targetDate : nil
            g.notes = notes.isEmpty ? nil : notes
            g.isCompleted = current >= target
            
            let ok = await goalManager.updateGoal(g)
            if ok { dismiss() }
        } else {
            let g = Goal(
                name: name,
                type: goalType,
                targetAmount: target,
                targetDate: hasTargetDate ? targetDate : nil,
                icon: goalType.defaultIcon,
                colorToken: goalType.defaultColor,
                notes: notes.isEmpty ? nil : notes,
                userId: userId
            )
            let ok = await goalManager.createGoal(g)
            if ok { dismiss() }
        }
        
        isSaving = false
    }
}
