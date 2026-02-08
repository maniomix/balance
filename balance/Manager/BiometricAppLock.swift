import SwiftUI
import LocalAuthentication

// MARK: - App Lock Manager

class AppLockManager: ObservableObject {
    @Published var isUnlocked = false
    @AppStorage("app.biometric_enabled") var isBiometricEnabled = false
    
    private let context = LAContext()
    
    func authenticateWithBiometrics() async -> Bool {
        var error: NSError?
        
        // Check if biometric is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            return false
        }
        
        do {
            let reason = L10n.t("biometric.unlock_app")
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                await MainActor.run {
                    self.isUnlocked = true
                }
            }
            return success
        } catch {
            print("Biometric authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func lockApp() {
        isUnlocked = false
    }
    
    var biometricType: String {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "None"
        }
        
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric"
        }
    }
    
    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}

// MARK: - App Lock Screen

struct AppLockScreen: View {
    @EnvironmentObject var appLockManager: AppLockManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo/Icon
                ZStack {
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
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color(hexValue: 0x667EEA).opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 12) {
                    Text("Balance")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(L10n.t("biometric.unlock_to_continue"))
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Unlock Button
                Button {
                    Task {
                        let success = await appLockManager.authenticateWithBiometrics()
                        if !success {
                            showError = true
                            errorMessage = L10n.t("biometric.failed")
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: biometricIcon)
                            .font(.system(size: 20))
                        
                        Text(String(format: L10n.t("biometric.unlock_with"), appLockManager.biometricType))
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hexValue: 0x667EEA),
                                Color(hexValue: 0x764BA2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            // Auto-trigger authentication when screen appears
            _ = await appLockManager.authenticateWithBiometrics()
        }
    }
    
    private var biometricIcon: String {
        switch appLockManager.biometricType {
        case "Face ID":
            return "faceid"
        case "Touch ID":
            return "touchid"
        case "Optic ID":
            return "opticid"
        default:
            return "lock.fill"
        }
    }
}

// MARK: - Biometric Setting Row (for Settings)

struct BiometricSettingRow: View {
    @EnvironmentObject var appLockManager: AppLockManager
    @State private var showAlert = false
    
    var body: some View {
        HStack {
            Image(systemName: biometricIcon)
                .font(.system(size: 18))
                .foregroundStyle(DS.Colors.text)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(appLockManager.biometricType)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.Colors.text)
                
                Text(L10n.t("biometric.app_lock_description"))
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.subtext)
            }
            
            Spacer()
            
            Toggle("", isOn: $appLockManager.isBiometricEnabled)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(hexValue: 0x667EEA)))
                .disabled(!appLockManager.isBiometricAvailable)
        }
        .opacity(appLockManager.isBiometricAvailable ? 1.0 : 0.5)
        .onTapGesture {
            if !appLockManager.isBiometricAvailable {
                showAlert = true
            }
        }
        .alert(L10n.t("biometric.not_available"), isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(L10n.t("biometric.enable_in_settings"))
        }
    }
    
    private var biometricIcon: String {
        switch appLockManager.biometricType {
        case "Face ID":
            return "faceid"
        case "Touch ID":
            return "touchid"
        case "Optic ID":
            return "opticid"
        default:
            return "lock.shield.fill"
        }
    }
}

// MARK: - App Lock Wrapper

struct AppLockWrapper<Content: View>: View {
    @EnvironmentObject var appLockManager: AppLockManager
    @Environment(\.scenePhase) var scenePhase
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            if appLockManager.isBiometricEnabled && !appLockManager.isUnlocked {
                AppLockScreen()
                    .transition(.opacity)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if appLockManager.isBiometricEnabled {
                switch newPhase {
                case .background, .inactive:
                    // Lock app when going to background
                    appLockManager.lockApp()
                case .active:
                    // App will auto-authenticate when lock screen appears
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}
