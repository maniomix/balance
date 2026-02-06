import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct UltimateLoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var biometricManager = BiometricAuthManager()
    @StateObject private var googleSignInManager = GoogleSignInManager()
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showResetSuccess = false
    @State private var showBiometricError = false
    @State private var biometricErrorMessage = ""
    @State private var showSocialError = false
    @State private var socialErrorMessage = ""
    
    var onSignUp: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            UltimateAuthComponents.AnimatedGradientBackground()
            
            // Content - Centered
            VStack {
                Spacer()
                
                VStack(spacing: 40) {
                    logoSection
                    loginCard
                        .padding(.horizontal, 24)
                    socialSection
                        .padding(.horizontal, 24)
                    signUpLink
                }
                
                Spacer()
            }
            
            if isLoading {
                UltimateAuthComponents.AuthLoadingOverlay(message: "Signing in...")
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(email: $resetEmail, showSuccess: $showResetSuccess)
        }
        .alert("Biometric Authentication", isPresented: $showBiometricError) {
            Button("OK") {
                showBiometricError = false
            }
        } message: {
            Text(biometricErrorMessage)
        }
        .alert("Sign In Error", isPresented: $showSocialError) {
            Button("OK") {
                showSocialError = false
            }
        } message: {
            Text(socialErrorMessage)
        }
    }
    
    // MARK: - Logo
    
    private var logoSection: some View {
        VStack(spacing: 12) {
            Text("Balance")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Welcome back")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    // MARK: - Login Card
    
    private var loginCard: some View {
        UltimateAuthComponents.GlassCard {
            VStack(spacing: 20) {
                UltimateAuthComponents.FloatingTextField(
                    text: $email,
                    placeholder: "Email",
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    showSecure: .constant(false)
                )
                
                UltimateAuthComponents.FloatingTextField(
                    text: $password,
                    placeholder: "Password",
                    icon: "lock.fill",
                    isSecure: true,
                    showSecure: $showPassword
                )
                
                // Forgot Password
                HStack {
                    Spacer()
                    Button {
                        resetEmail = email
                        showForgotPassword = true
                    } label: {
                        Text("Forgot Password?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                // Error
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .padding(.vertical, 8)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Sign In Button
                Button {
                    signIn()
                } label: {
                    HStack(spacing: 10) {
                        if isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Sign In")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.white)
                    .foregroundStyle(.black)
                    .cornerRadius(16)
                }
                .disabled(isLoading || !isFormValid)
                .opacity(isFormValid ? 1.0 : 0.5)
            }
            .padding(24)
        }
    }
    
    // MARK: - Social Login
    
    private var socialSection: some View {
        VStack(spacing: 16) {
            // Divider
            HStack {
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 1)
                
                Text("OR")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 1)
            }
            
            // Social Buttons
            HStack(spacing: 16) {
                // Face ID / Touch ID
                if biometricManager.isBiometricAvailable() {
                    UltimateAuthComponents.SocialAuthButton(
                        icon: biometricManager.biometricIcon,
                        color: .white,
                        action: authenticateWithBiometric
                    )
                }
                
                // Google Sign In
                UltimateAuthComponents.SocialAuthButton(
                    icon: "g.circle.fill",
                    color: .white,
                    action: signInWithGoogle
                )
            }
        }
    }
    
    // MARK: - Sign Up Link
    
    private var signUpLink: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                onSignUp()
            }
        } label: {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundStyle(.white.opacity(0.6))
                Text("Sign Up")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .font(.system(size: 15))
        }
    }
    
    // MARK: - Actions
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    private func signIn() {
        isLoading = true
        
        Task {
            do {
                try await authManager.signIn(
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password.trimmingCharacters(in: .whitespaces)
                )
                
                await MainActor.run {
                    // Save credentials for biometric if enabled
                    if biometricManager.isBiometricEnabled {
                        _ = biometricManager.saveCredentials(
                            email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                            password: password.trimmingCharacters(in: .whitespaces)
                        )
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func authenticateWithBiometric() {
        Task {
            do {
                // Check if biometric is enabled and credentials are saved
                guard biometricManager.isBiometricEnabled,
                      let credentials = biometricManager.loadCredentials() else {
                    await MainActor.run {
                        biometricErrorMessage = "Biometric authentication is not set up. Please sign in with your email and password first."
                        showBiometricError = true
                    }
                    return
                }
                
                // Authenticate with biometric
                let success = try await biometricManager.authenticate()
                
                guard success else {
                    return
                }
                
                // Sign in with saved credentials
                await MainActor.run {
                    isLoading = true
                }
                
                try await authManager.signIn(email: credentials.email, password: credentials.password)
                
                await MainActor.run {
                    isLoading = false
                }
                
            } catch let error as BiometricError {
                await MainActor.run {
                    if error != .userCancelled {
                        biometricErrorMessage = error.errorDescription ?? "Authentication failed"
                        showBiometricError = true
                    }
                }
            } catch {
                await MainActor.run {
                    biometricErrorMessage = "Sign in failed. Please try again."
                    showBiometricError = true
                }
            }
        }
    }
    
    
    private func signInWithGoogle() {
        isLoading = true
        
        Task {
            do {
                _ = try await googleSignInManager.signInWithGoogle()
                
                await MainActor.run {
                    isLoading = false
                    // AuthManager will handle the auth state change
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    socialErrorMessage = "Google Sign In failed. Please try again."
                    showSocialError = true
                }
            }
        }
    }
}

// MARK: - Forgot Password Sheet

struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var email: String
    @Binding var showSuccess: Bool
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Reset your password")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(DS.Colors.text)
                    
                    Text("Enter your email and we'll send you a link to reset your password")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Colors.subtext)
                        .multilineTextAlignment(.center)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(DS.TextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button {
                        sendResetEmail()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text("Send Reset Link")
                            }
                        }
                    }
                    .buttonStyle(DS.PrimaryButton())
                    .disabled(email.isEmpty || isLoading)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendResetEmail() {
        isLoading = true
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false
            if error == nil {
                showSuccess = true
                dismiss()
            }
        }
    }
}
