import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var currentUser: User?
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    init() {
        // چک کردن اگه قبلاً login کرده
        self.currentUser = Auth.auth().currentUser
        
        // گوش دادن به تغییرات auth state
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }
    
    // Sign up با email/password
    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.currentUser = result.user
            
            // Send verification email
            try await result.user.sendEmailVerification()
            print("✅ Verification email sent to: \(email)")
            
            isLoading = false
        } catch let error as NSError {
            isLoading = false
            
            // بهبود error messages
            switch error.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                errorMessage = "This email is already registered. Please sign in instead."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Invalid email format."
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "Password is too weak. Use at least 6 characters."
            case AuthErrorCode.operationNotAllowed.rawValue:
                errorMessage = "Email/password sign up is not enabled."
            default:
                errorMessage = error.localizedDescription
            }
            
            throw error
        }
    }
    
    // Resend verification email
    func resendVerificationEmail() async throws {
        guard let user = Auth.auth().currentUser else {
            throw FirestoreError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await user.sendEmailVerification()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // Reload user to check verification status
    func reloadUser() async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        try await user.reload()
        self.currentUser = Auth.auth().currentUser
    }
    
    // Sign in با email/password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        // Debug: چک کردن credentials
        print("🔐 Attempting sign in:")
        print("  Email: '\(email)'")
        print("  Password length: \(password.count)")
        print("  Email trimmed: '\(email.trimmingCharacters(in: .whitespaces))'")
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.currentUser = result.user
            print("✅ Sign in successful for: \(result.user.email ?? "no email")")
            isLoading = false
        } catch let error as NSError {
            isLoading = false
            
            print("❌ Sign in failed with code: \(error.code)")
            
            // بهبود error messages
            switch error.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Incorrect password. Please try again."
            case AuthErrorCode.userNotFound.rawValue:
                errorMessage = "No account found with this email. Please sign up first."
            case AuthErrorCode.invalidEmail.rawValue:
                errorMessage = "Invalid email format."
            case AuthErrorCode.userDisabled.rawValue:
                errorMessage = "This account has been disabled."
            case AuthErrorCode.invalidCredential.rawValue:
                errorMessage = "Invalid email or password. Please check and try again."
            case AuthErrorCode.tooManyRequests.rawValue:
                errorMessage = "Too many failed attempts. Please try again later or reset your password."
            default:
                errorMessage = error.localizedDescription
            }
            
            throw error
        }
    }
    
    // Sign out
    func signOut() throws {
        try Auth.auth().signOut()
        self.currentUser = nil
    }
    
    // Reset password
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // Delete account
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await user.delete()
            self.currentUser = nil
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
