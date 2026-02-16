import Foundation
import SwiftUI
import Supabase
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    private var supabase: SupabaseManager {
        SupabaseManager.shared
    }
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    init() {
        // Sync with Supabase auth state
        Task {
            for await state in await supabase.client.auth.authStateChanges {
                await MainActor.run {
                    self.currentUser = state.session?.user
                    self.isAuthenticated = state.session != nil
                    print("🔐 Auth state: \(self.isAuthenticated)")
                }
            }
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, displayName: String = "User") async throws {
        try await supabase.signUp(email: email, password: password, displayName: displayName)
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        try await supabase.signIn(email: email, password: password)
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try supabase.signOut()
        isAuthenticated = false
        currentUser = nil
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        try await supabase.resetPassword(email: email)
    }
    
    // MARK: - Change Password
    
    func changePassword(newPassword: String) async throws {
        try await supabase.changePassword(newPassword: newPassword)
    }
    
    // MARK: - Email Verification
    
    func reloadUser() async throws {
        // Supabase handles email verification differently
        // Just refresh the session
        _ = try await supabase.client.auth.session
    }
    
    func resendVerificationEmail() async throws {
        guard let email = currentUser?.email else {
            throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "No email found"])
        }
        // Supabase doesn't have a direct resend method
        // User needs to check their email
        print("⚠️ Check your email for verification link")
    }
}
