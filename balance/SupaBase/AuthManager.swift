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
    
    // Helper properties
    var userEmail: String {
        currentUser?.email ?? "User"
    }
    
    var userInitial: String {
        guard let email = currentUser?.email else {
            return "U"
        }
        return String(email.prefix(1)).uppercased()
    }
    
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
        print("🔵 AuthManager: Starting sign up for \(email)")
        try await supabase.signUp(email: email, password: password, displayName: displayName)
        print("🔵 AuthManager: Sign up completed")
        
        // Manually check and update auth state
        do {
            let session = try await supabase.client.auth.session
            await MainActor.run {
                self.currentUser = session.user
                self.isAuthenticated = true
                print("🔵 AuthManager: Manually set isAuthenticated = true")
                print("🔵 AuthManager: currentUser = \(session.user.email ?? "nil")")
            }
        } catch {
            print("⚠️ Could not get session after signup: \(error)")
        }
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
        
        // Resend confirmation email - correct parameter order
        try await supabase.client.auth.resend(
            email: email,
            type: .signup
        )
        
        print("✅ Verification email sent to \(email)")
    }
}
