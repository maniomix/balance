import Foundation
import Combine
import LocalAuthentication
import Security

class BiometricAuthManager: ObservableObject {
    @Published var isBiometricEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricEnabled, forKey: "biometricEnabled")
        }
    }
    
    init() {
        self.isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
    }
    
    // MARK: - Biometric Type
    
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.fill"
        }
    }
    
    var biometricName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometric"
        }
    }
    
    // MARK: - Check Availability
    
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // MARK: - Authenticate
    
    func authenticate(reason: String = "Sign in to Balance") async throws -> Bool {
        let context = LAContext()
        
        // Check if biometric is available
        guard isBiometricAvailable() else {
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            switch error.code {
            case .userCancel:
                throw BiometricError.userCancelled
            case .userFallback:
                throw BiometricError.fallback
            case .biometryNotAvailable:
                throw BiometricError.notAvailable
            case .biometryNotEnrolled:
                throw BiometricError.notEnrolled
            case .biometryLockout:
                throw BiometricError.lockout
            default:
                throw BiometricError.failed
            }
        }
    }
    
    // MARK: - Save Credentials to Keychain
    
    func saveCredentials(email: String, password: String) -> Bool {
        // Delete old credentials first
        deleteCredentials()
        
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecAttrService as String: "com.balance.app",
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // Also save email separately for easy retrieval
            UserDefaults.standard.set(email, forKey: "biometricEmail")
            return true
        }
        
        print("❌ Failed to save credentials: \(status)")
        return false
    }
    
    // MARK: - Load Credentials from Keychain
    
    func loadCredentials() -> (email: String, password: String)? {
        guard let email = UserDefaults.standard.string(forKey: "biometricEmail") else {
            return nil
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecAttrService as String: "com.balance.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return (email, password)
    }
    
    // MARK: - Delete Credentials
    
    func deleteCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.balance.app"
        ]
        
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: "biometricEmail")
    }
    
    // MARK: - Enable/Disable Biometric
    
    func enableBiometric(email: String, password: String) async throws {
        // First authenticate
        let success = try await authenticate(reason: "Enable \(biometricName) for Balance")
        
        guard success else {
            throw BiometricError.failed
        }
        
        // Save credentials
        guard saveCredentials(email: email, password: password) else {
            throw BiometricError.keychainError
        }
        
        isBiometricEnabled = true
    }
    
    func disableBiometric() {
        deleteCredentials()
        isBiometricEnabled = false
    }
}

// MARK: - Biometric Type

enum BiometricType {
    case faceID
    case touchID
    case none
}

// MARK: - Biometric Errors

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case failed
    case userCancelled
    case fallback
    case lockout
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric data enrolled. Please set up Face ID or Touch ID in Settings"
        case .failed:
            return "Biometric authentication failed"
        case .userCancelled:
            return "Authentication cancelled"
        case .fallback:
            return "Fallback to password"
        case .lockout:
            return "Biometric authentication is locked. Please try again later"
        case .keychainError:
            return "Failed to save credentials securely"
        }
    }
}
