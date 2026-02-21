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
    
    private var isEmailVerified: Bool {
        // Supabase handles verification differently
        return true
    }
    
    private var memberSince: String {
        return "Member"
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
        }
        .padding(.vertical)
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
                Divider().padding(.leading, 40)
                accountRow(icon: "checkmark.shield.fill", title: "Verification", value: "Verified", color: .green)
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
            signOut()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 20)
    }
    
    // MARK: - Actions
    
    private func signOut() {
        do {
            try authManager.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
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
