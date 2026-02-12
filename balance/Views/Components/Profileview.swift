import SwiftUI
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @Binding var store: Store
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var firestoreManager: FirestoreManager
    
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileImageData: Data?
    @State private var showEditName = false
    @State private var displayName = ""
    @State private var showDeleteAccountAlert = false
    @State private var isSavingProfile = false
    
    private var user: User? {
        authManager.currentUser
    }
    
    private var userEmail: String {
        user?.email ?? "No email"
    }
    
    private var isEmailVerified: Bool {
        user?.isEmailVerified ?? false
    }
    
    private var memberSince: String {
        guard let creationDate = user?.metadata.creationDate else {
            return "Unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: creationDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Cards
                    statsSection
                    
                    // Account Info
                    accountInfoSection
                    
                    // Actions
                    actionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .background(DS.Colors.bg.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Load profile when view appears
                await loadProfile()
            }
        }
        .sheet(isPresented: $showEditName) {
            editNameSheet
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Picture
            ZStack {
                if let profileImage {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hexValue: 0x667EEA),
                                    Color(hexValue: 0x764BA2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(userInitials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
                
                // Camera button
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Circle()
                        .fill(DS.Colors.surface)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(DS.Colors.text)
                        )
                        .overlay(
                            Circle()
                                .stroke(DS.Colors.grid, lineWidth: 2)
                        )
                }
                .offset(x: 35, y: 35)
            }
            .onChange(of: selectedImage) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                        profileImageData = data
                        
                        // Auto-save profile image
                        await saveProfile()
                    }
                }
            }
            
            // Name
            VStack(spacing: 4) {
                Text(displayName.isEmpty ? "User" : displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DS.Colors.text)
                
                HStack(spacing: 6) {
                    Text(userEmail)
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Colors.subtext)
                    
                    if isEmailVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                    }
                }
            }
            
            // Edit Profile Button
            Button {
                showEditName = true
            } label: {
                Text("Edit Profile")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Colors.text)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(DS.Colors.surface2)
                    )
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        DS.Card {
            VStack(spacing: 16) {
                Text("Your Statistics")
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider().overlay(DS.Colors.grid)
                
                HStack(spacing: 0) {
                    statItem(
                        value: "\(store.transactions.count)",
                        label: "Transactions"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .overlay(DS.Colors.grid)
                    
                    statItem(
                        value: DS.Format.currency(store.transactions.reduce(0) { $0 + $1.amount }),
                        label: "Total Spent"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .overlay(DS.Colors.grid)
                    
                    statItem(
                        value: "\(store.budgetsByMonth.count)",
                        label: "Months"
                    )
                }
            }
        }
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(DS.Colors.text)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(DS.Colors.subtext)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Account Info
    
    private var accountInfoSection: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Account Information")
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)
                
                Divider().overlay(DS.Colors.grid)
                
                infoRow(
                    icon: "envelope.fill",
                    label: "Email",
                    value: userEmail
                )
                
                infoRow(
                    icon: "calendar",
                    label: "Member Since",
                    value: memberSince
                )
                
                infoRow(
                    icon: isEmailVerified ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
                    label: "Verification",
                    value: isEmailVerified ? "Verified" : "Not Verified",
                    valueColor: isEmailVerified ? .green : .orange
                )
            }
        }
    }
    
    private func infoRow(icon: String, label: String, value: String, valueColor: Color? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hexValue: 0x667EEA))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.subtext)
                
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(valueColor ?? DS.Colors.text)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                ChangePasswordView()
            } label: {
                actionButton(
                    icon: "lock.fill",
                    title: "Change Password",
                    color: .blue
                )
            }
            
            NavigationLink {
                ExportDataView(store: $store)
            } label: {
                actionButton(
                    icon: "arrow.down.doc.fill",
                    title: "Export Data",
                    color: .green
                )
            }
            
            // Delete Account
            Button {
                showDeleteAccountAlert = true
            } label: {
                actionButton(
                    icon: "trash.fill",
                    title: "Delete Account",
                    color: .red
                )
            }
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure? This will permanently delete your account and all data. This action cannot be undone.")
        }
    }
    
    private func actionButton(icon: String, title: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.Colors.text)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(DS.Colors.subtext)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DS.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
    
    // MARK: - Edit Name Sheet
    
    private var editNameSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DS.Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Display Name")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                        
                        TextField("Enter your name", text: $displayName)
                            .textFieldStyle(DS.TextFieldStyle())
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(DS.Colors.bg.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showEditName = false
                    }
                    .foregroundStyle(DS.Colors.subtext)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                            showEditName = false
                        }
                    }
                    .foregroundStyle(Color(hexValue: 0x667EEA))
                    .disabled(isSavingProfile)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func loadProfile() async {
        do {
            if let profile = try await firestoreManager.loadProfile() {
                displayName = profile.displayName
                
                if let imageData = profile.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    profileImage = Image(uiImage: uiImage)
                    profileImageData = imageData
                }
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func saveProfile() async {
        isSavingProfile = true
        
        do {
            try await firestoreManager.saveProfile(
                displayName: displayName,
                profileImageData: profileImageData
            )
            isSavingProfile = false
        } catch {
            print("Error saving profile: \(error)")
            isSavingProfile = false
        }
    }
    
    private var userInitials: String {
        if !displayName.isEmpty {
            let components = displayName.split(separator: " ")
            if components.count >= 2 {
                return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
            }
            return String(displayName.prefix(1)).uppercased()
        }
        
        if let email = user?.email {
            return String(email.prefix(1)).uppercased()
        }
        
        return "U"
    }
    
    private func deleteAccount() {
        Task {
            do {
                // Delete Firestore data
                try await firestoreManager.deleteUserData()
                
                // Delete account
                try await authManager.deleteAccount()
                
                // Clear local store
                store = Store()
            } catch {
                print("Error deleting account: \(error)")
            }
        }
    }
}

// MARK: - Change Password View

struct ChangePasswordView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DS.Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Change Your Password")
                            .font(DS.Typography.section)
                            .foregroundStyle(DS.Colors.text)
                        
                        Divider().overlay(DS.Colors.grid)
                        
                        // Current Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current Password")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                            
                            SecureField("Enter current password", text: $currentPassword)
                                .textFieldStyle(DS.TextFieldStyle())
                        }
                        
                        // New Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("New Password")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                            
                            SecureField("At least 6 characters", text: $newPassword)
                                .textFieldStyle(DS.TextFieldStyle())
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm New Password")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                            
                            SecureField("Re-enter new password", text: $confirmPassword)
                                .textFieldStyle(DS.TextFieldStyle())
                        }
                        
                        // Password Requirements
                        VStack(alignment: .leading, spacing: 4) {
                            requirementRow(
                                met: newPassword.count >= 6,
                                text: "At least 6 characters"
                            )
                            
                            requirementRow(
                                met: newPassword == confirmPassword && !newPassword.isEmpty,
                                text: "Passwords match"
                            )
                        }
                        
                        // Error
                        if showError {
                            Text(errorMessage)
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.negative)
                                .padding(.vertical, 4)
                        }
                        
                        // Change Button
                        Button {
                            changePassword()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "lock.rotation")
                                    Text("Change Password")
                                }
                            }
                        }
                        .buttonStyle(DS.PrimaryButton())
                        .disabled(!isFormValid || isLoading)
                    }
                }
                
                Spacer()
            }
            .padding(16)
        }
        .background(DS.Colors.bg.ignoresSafeArea())
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been changed successfully.")
        }
    }
    
    private func requirementRow(met: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(met ? DS.Colors.positive : DS.Colors.subtext)
                .font(.system(size: 12))
            
            Text(text)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.subtext)
        }
    }
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                // Re-authenticate user
                guard let email = Auth.auth().currentUser?.email else { return }
                let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
                try await Auth.auth().currentUser?.reauthenticate(with: credential)
                
                // Change password
                try await Auth.auth().currentUser?.updatePassword(to: newPassword)
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    @Binding var store: Store
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DS.Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Your Data")
                            .font(DS.Typography.section)
                            .foregroundStyle(DS.Colors.text)
                        
                        Text("You can export your transactions and budgets to CSV or Excel format from the Insights tab.")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.subtext)
                    }
                }
                
                DS.Card {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(Color(hexValue: 0x667EEA))
                                .font(.system(size: 20))
                            
                            Text("How to Export")
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)
                        }
                        
                        Divider().overlay(DS.Colors.grid)
                        
                        instructionRow(number: "1", text: "Go to the Insights tab")
                        instructionRow(number: "2", text: "Tap on Export button")
                        instructionRow(number: "3", text: "Choose CSV or Excel format")
                        instructionRow(number: "4", text: "Share or save your file")
                    }
                }
                
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Go to Insights")
                    }
                }
                .buttonStyle(DS.PrimaryButton())
                
                Spacer()
            }
            .padding(16)
        }
        .background(DS.Colors.bg.ignoresSafeArea())
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hexValue: 0x667EEA).opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(
                    Text(number)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hexValue: 0x667EEA))
                )
            
            Text(text)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.text)
            
            Spacer()
        }
    }
}
