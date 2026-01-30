import SwiftUI
import FirebaseAuth
import LocalAuthentication

struct UltimateSignUpView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorText = ""
    
    var onSignIn: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
            FloatingParticles()
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 50)
                    
                    logoSection
                        .padding(.bottom, 40)
                    
                    signUpCard
                        .padding(.horizontal, 24)
                    
                    socialSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    
                    signInLink
                        .padding(.top, 28)
                    
                    Spacer().frame(height: 40)
                }
            }
            .ignoresSafeArea(.keyboard)
            
            if isLoading {
                AuthLoadingOverlay(message: "Creating account...")
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Logo
    
    private var logoSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x667EEA).opacity(0.3),
                                Color(hex: 0x764BA2).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .blur(radius: 18)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 45, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0x667EEA), Color(hex: 0x764BA2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("Balance")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: 0x667EEA), Color(hex: 0xF093FB)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color(hex: 0x667EEA).opacity(0.3), radius: 15, x: 0, y: 8)
            
            Text("Create your account")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
    
    // MARK: - Sign Up Card
    
    private var signUpCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                FloatingTextField(
                    text: $email,
                    placeholder: "Email",
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    showSecure: .constant(false)
                )
                
                FloatingTextField(
                    text: $password,
                    placeholder: "Password",
                    icon: "lock.fill",
                    isSecure: true,
                    showSecure: $showPassword
                )
                
                FloatingTextField(
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
                GradientButton(
                    title: "Create Account",
                    icon: "person.badge.plus",
                    isLoading: isLoading,
                    isEnabled: isFormValid,
                    action: signUp
                )
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
                SocialAuthButton(
                    icon: "apple.logo",
                    color: .white,
                    action: { print("Apple Sign Up") }
                )
                
                SocialAuthButton(
                    icon: "g.circle.fill",
                    color: Color(hex: 0x4285F4),
                    action: { print("Google Sign Up") }
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
                    .foregroundStyle(.white.opacity(0.7))
                Text("Sign In")
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0x667EEA), Color(hex: 0xF093FB)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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
}
