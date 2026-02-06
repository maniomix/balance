import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct UltimateSignUpView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var googleSignInManager = GoogleSignInManager()
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorText = ""
    @State private var showSocialError = false
    @State private var socialErrorMessage = ""
    
    var onSignIn: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            UltimateAuthComponents.AnimatedGradientBackground()
            
            // Content - Centered Vertically
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Dynamic top spacer to center content
                        Spacer()
                            .frame(minHeight: 0)
                        
                        VStack(spacing: 32) {
                            logoSection
                            signUpCard
                                .padding(.horizontal, 24)
                            socialSection
                                .padding(.horizontal, 24)
                            signInLink
                        }
                        .frame(minHeight: geometry.size.height)
                        
                        // Dynamic bottom spacer
                        Spacer()
                            .frame(minHeight: 0)
                    }
                }
            }
            
            if isLoading {
                UltimateAuthComponents.AuthLoadingOverlay(message: "Creating account...")
            }
        }
        .ignoresSafeArea()
        .alert("Sign Up Error", isPresented: $showSocialError) {
            Button("OK") {
                showSocialError = false
            }
        } message: {
            Text(socialErrorMessage)
        }
    }
    
    // MARK: - Logo
    
    private var logoSection: some View {
        VStack(spacing: 8) {
            Text("Balance")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Create your account")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    // MARK: - Sign Up Card
    
    private var signUpCard: some View {
        UltimateAuthComponents.GlassCard {
            VStack(spacing: 16) {
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
                
                UltimateAuthComponents.FloatingTextField(
                    text: $confirmPassword,
                    placeholder: "Confirm Password",
                    icon: "lock.fill",
                    isSecure: true,
                    showSecure: $showConfirmPassword
                )
                
                // Password Strength & Requirements
                passwordValidation
                
                // Error
                if showError {
                    Text(errorText)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .transition(.scale.combined(with: .opacity))
                }
                
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Sign Up Button
                Button {
                    signUp()
                } label: {
                    HStack(spacing: 10) {
                        if isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Create Account")
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
                .padding(.top, 8)
            }
            .padding(22)
        }
    }
    
    // MARK: - Password Validation
    
    private var passwordValidation: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Strength Bar
            if !password.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Password Strength:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text(passwordStrengthText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(passwordStrengthColor)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(passwordStrengthColor)
                                .frame(width: geo.size.width * passwordStrength)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: passwordStrength)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(.bottom, 4)
            }
            
            // Requirements
            VStack(alignment: .leading, spacing: 6) {
                requirementRow(
                    met: password.count >= 6,
                    text: "At least 6 characters"
                )
                
                requirementRow(
                    met: password == confirmPassword && !password.isEmpty,
                    text: "Passwords match"
                )
            }
        }
    }
    
    private func requirementRow(met: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))
                .foregroundStyle(met ? .green : .white.opacity(0.4))
            
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    // MARK: - Social Section
    
    private var socialSection: some View {
        VStack(spacing: 14) {
            HStack {
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(height: 1)
                Text("OR")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(height: 1)
            }
            
            HStack(spacing: 14) {
                UltimateAuthComponents.SocialAuthButton(
                    icon: "g.circle.fill",
                    color: .white,
                    action: signUpWithGoogle
                )
            }
        }
    }
    
    // MARK: - Sign In Link
    
    private var signInLink: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                onSignIn()
            }
        } label: {
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(.white.opacity(0.6))
                Text("Sign In")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .font(.system(size: 14))
        }
    }
    
    // MARK: - Password Strength
    
    private var passwordStrength: Double {
        var strength = 0.0
        if password.count >= 6 { strength += 0.25 }
        if password.count >= 8 { strength += 0.25 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { strength += 0.15 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { strength += 0.15 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 0.1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()")) != nil { strength += 0.1 }
        return min(strength, 1.0)
    }
    
    private var passwordStrengthText: String {
        if passwordStrength < 0.3 { return "Weak" }
        if passwordStrength < 0.6 { return "Fair" }
        if passwordStrength < 0.8 { return "Good" }
        return "Strong"
    }
    
    private var passwordStrengthColor: Color {
        if passwordStrength < 0.3 { return .red }
        if passwordStrength < 0.6 { return .orange }
        if passwordStrength < 0.8 { return .yellow }
        return .green
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func signUp() {
        showError = false
        errorText = ""
        
        guard password == confirmPassword else {
            errorText = "Passwords don't match"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await authManager.signUp(
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password.trimmingCharacters(in: .whitespaces)
                )
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    
    private func signUpWithGoogle() {
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
