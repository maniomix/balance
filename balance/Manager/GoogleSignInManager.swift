import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

class GoogleSignInManager: ObservableObject {
    
    // MARK: - Sign In with Google
    
    func signInWithGoogle() async throws -> AuthDataResult {
        // Get client ID from Firebase
        guard let clientID = Auth.auth().app?.options.clientID else {
            throw GoogleSignInError.noClientID
        }
        
        // Configure Google Sign In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw GoogleSignInError.noViewController
        }
        
        // Start Google Sign In flow
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw GoogleSignInError.noIDToken
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Create Firebase credential
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
        
        // Sign in to Firebase
        let authResult = try await Auth.auth().signIn(with: credential)
        
        return authResult
    }
    
    // MARK: - Sign Out
    
    func signOutFromGoogle() {
        GIDSignIn.sharedInstance.signOut()
    }
}

// MARK: - Errors

enum GoogleSignInError: LocalizedError {
    case noClientID
    case noViewController
    case noIDToken
    case signInCancelled
    
    var errorDescription: String? {
        switch self {
        case .noClientID:
            return "Google Sign In is not configured properly"
        case .noViewController:
            return "No view controller available"
        case .noIDToken:
            return "Failed to get ID token from Google"
        case .signInCancelled:
            return "Sign in was cancelled"
        }
    }
}
