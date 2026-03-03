import SwiftUI
import PhotosUI
import Supabase

struct ProfileView: View {
    @Binding var store: Store
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileImageData: Data?
    @State private var showEditName = false
    @State private var displayName = ""
    @State private var isSavingProfile = false
    
    private var user: Supabase.User? {
        authManager.currentUser
    }
    
    private var userEmail: String {
        user?.email ?? "No email"
    }
    
    private var memberSince: String {
        guard let createdAt = user?.createdAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: createdAt)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader
                        
                        // Account Info
                        accountInfoSection
                        
                        // Actions
                        actionsSection
                        
                        // Sign Out
                        signOutButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Picture
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(DS.Colors.accent.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay {
                        if let profileImage = profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Text(userEmail.prefix(1).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(DS.Colors.accent)
                        }
                    }
                
                // Camera Button
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Circle()
                        .fill(DS.Colors.surface)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(DS.Colors.text)
                        }
                }
            }
            
            // Display Name
            VStack(spacing: 4) {
                Text(displayName.isEmpty ? "User" : displayName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DS.Colors.text)
                
                Text(userEmail)
                    .font(.system(size: 14))
                    .foregroundColor(DS.Colors.subtext)
            }
            
            // Edit Profile Button
            Button {
                showEditName = true
            } label: {
                Text("Edit Profile")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DS.Colors.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(DS.Colors.accent.opacity(0.1), in: Capsule())
            }
            .alert("Edit Display Name", isPresented: $showEditName) {
                TextField("Your name", text: $displayName)
                    .textInputAutocapitalization(.words)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    saveDisplayName()
                }
            } message: {
                Text("Enter your display name")
            }
        }
        .padding(.vertical)
        .onChange(of: selectedImage) { _, newItem in
            loadSelectedPhoto(newItem)
        }
        .onAppear {
            loadSavedProfile()
        }
    }
    
    // MARK: - Profile Persistence
    
    private func loadSavedProfile() {
        guard let userId = user?.id.uuidString else { return }
        
        if let savedName = UserDefaults.standard.string(forKey: "profile_name_\(userId)") {
            displayName = savedName
        }
        
        if let savedImageData = UserDefaults.standard.data(forKey: "profile_image_\(userId)"),
           let uiImage = UIImage(data: savedImageData) {
            profileImageData = savedImageData
            profileImage = Image(uiImage: uiImage)
        }
    }
    
    private func saveDisplayName() {
        guard let userId = user?.id.uuidString else { return }
        UserDefaults.standard.set(displayName, forKey: "profile_name_\(userId)")
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    profileImageData = data
                    profileImage = Image(uiImage: uiImage)
                    
                    if let userId = user?.id.uuidString {
                        // Save compressed version
                        if let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                            UserDefaults.standard.set(compressed, forKey: "profile_image_\(userId)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Account Info Section
    
    private var accountInfoSection: some View {
        VStack(spacing: 0) {
            Text("Account Information")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DS.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                accountRow(icon: "envelope.fill", title: "Email", value: userEmail, color: .blue)
                Divider().padding(.leading, 40)
                accountRow(icon: "calendar", title: "Member Since", value: memberSince, color: .green)
            }
            .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func accountRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(DS.Colors.subtext)
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(DS.Colors.text)
            }
            
            Spacer()
        }
        .padding(14)
    }
    
    // MARK: - Actions Section
    
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
        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Sign Out Button
    
    private var signOutButton: some View {
        Button {
            Haptics.warning()
            Task {
                do {
                    // Save to cloud before signing out
                    if let userId = authManager.currentUser?.uid {
                        let currentStore = Store.load(userId: userId)
                        try? await supabaseManager.saveStore(currentStore)
                    }
                    try authManager.signOut()
                } catch {
                    print("Sign out error: \(error)")
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Sign Out")
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.5))
            }
            .foregroundStyle(.red)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red.opacity(0.12), lineWidth: 0.8)
                    )
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Change Password View

struct ChangePasswordView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Change Your Password")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DS.Colors.text)
                    
                    Divider()
                    
                    // New Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Password")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.Colors.subtext)
                        
                        SecureField("At least 6 characters", text: $newPassword)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                    }
                    
                    // Confirm Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm New Password")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.Colors.subtext)
                        
                        SecureField("Re-enter new password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
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
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .padding(.vertical, 4)
                    }
                    
                    // Change Button
                    Button {
                        changePassword()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "lock.rotation")
                                Text("Change Password")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? DS.Colors.accent : DS.Colors.subtext, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                    }
                    .disabled(!isFormValid || isLoading)
                }
                .padding()
                .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding()
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
                .foregroundStyle(met ? .green : DS.Colors.subtext)
                .font(.system(size: 12))
            
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.subtext)
        }
    }
    
    private var isFormValid: Bool {
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
                try await authManager.changePassword(newPassword: newPassword)
                
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

#Preview {
    ProfileView(store: .constant(Store()))
        .environmentObject(AuthManager.shared)
        .environmentObject(SupabaseManager.shared)
}
