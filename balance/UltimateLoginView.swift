import SwiftUI
import FirebaseAuth
import AuthenticationServices
import LocalAuthentication

struct UltimateLoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showResetSuccess = false
    @State private var showBiometricError = false
    @State private var emailFocused = false
    @State private var passwordFocused = false
    
    var onSignUp: () -> Void
    
    var body: some View {
        ZStack {
            // Animated Gradient Background
            AnimatedGradientBackground()
            
            // Floating Particles
            FloatingParticles()
            
            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    
                    // Logo & Title
                    logoSection
                        .padding(.bottom, 50)
                    
                    // Login Card
                    loginCard
                        .padding(.horizontal, 24)
                    
                    // Social Login
                    socialLoginSection
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    // Sign Up Link
                    signUpLink
                        .padding(.top, 32)
                    
                    Spacer().frame(height: 40)
                }
            }
            .ignoresSafeArea(.keyboard)
            
            // Loading Overlay
            if isLoading {
                LoadingOverlay()
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(email: $resetEmail, showSuccess: $showResetSuccess)
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            // Animated Logo
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
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: 0x667EEA),
                                Color(hex: 0x764BA2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("Balance")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x667EEA),
                            Color(hex: 0xF093FB)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color(hex: 0x667EEA).opacity(0.3), radius: 20, x: 0, y: 10)
            
            Text("Welcome back! Sign in to continue")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
    
    // MARK: - Login Card
    
    private var loginCard: some View {
        GlassCard {
            VStack(spacing: 20) {
                // Email Field
                FloatingLabelTextField(
                    text: $email,
                    placeholder: "Email",
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    isFocused: $emailFocused
                )
                
                // Password Field
                FloatingLabelPasswordField(
                    password: $password,
                    showPassword: $showPassword,
                    isFocused: $passwordFocused
                )
                
                // Forgot Password
                HStack {
                    Spacer()
                    Button {
                        resetEmail = email
                        showForgotPassword = true
                    } label: {
                        Text("Forgot Password?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: 0x667EEA), Color(hex: 0x764BA2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                
                // Error Message
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
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                            Text("Sign In")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0x667EEA), Color(hex: 0x764BA2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .shadow(color: Color(hex: 0x667EEA).opacity(0.5), radius: 20, x: 0, y: 10)
                }
                .disabled(isLoading || !isFormValid)
                .opacity(isFormValid ? 1.0 : 0.6)
                .scaleEffect(isLoading ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
            }
            .padding(24)
        }
    }
    
    // MARK: - Social Login
    
    private var socialLoginSection: some View {
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
                SocialButton(
                    icon: biometricIcon,
                    color: Color(hex: 0x667EEA),
                    action: authenticateWithBiometric
                )
                
                // Apple Sign In
                SocialButton(
                    icon: "apple.logo",
                    color: .white,
                    action: signInWithApple
                )
                
                // Google Sign In
                SocialButton(
                    icon: "g.circle.fill",
                    color: Color(hex: 0x4285F4),
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
                    .foregroundStyle(.white.opacity(0.7))
                Text("Sign Up")
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0x667EEA), Color(hex: 0xF093FB)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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
        emailFocused = false
        passwordFocused = false
        
        Task {
            do {
                try await authManager.signIn(
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
    
    private var biometricIcon: String {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            default:
                return "lock.fill"
            }
        }
        return "lock.fill"
    }
    
    private func authenticateWithBiometric() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Sign in to Balance") { success, error in
                DispatchQueue.main.async {
                    if success {
                        // Load saved credentials and sign in
                        // For now, just show success
                        print("✅ Biometric authentication successful")
                    } else {
                        showBiometricError = true
                    }
                }
            }
        }
    }
    
    private func signInWithApple() {
        // Implement Apple Sign In
        print("🍎 Apple Sign In")
    }
    
    private func signInWithGoogle() {
        // Implement Google Sign In
        print("🔵 Google Sign In")
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Blur background
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Border gradient
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 20)
    }
}

// MARK: - Floating Label TextField

struct FloatingLabelTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    @Binding var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !text.isEmpty || isFocused {
                Text(placeholder)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .transition(.scale.combined(with: .opacity))
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24)
                
                TextField(placeholder, text: $text, onEditingChanged: { focused in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isFocused = focused
                    }
                })
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(isFocused ? 0.15 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isFocused ? [Color(hex: 0x667EEA), Color(hex: 0x764BA2)] : [.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - Floating Label Password Field

struct FloatingLabelPasswordField: View {
    @Binding var password: String
    @Binding var showPassword: Bool
    @Binding var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !password.isEmpty || isFocused {
                Text("Password")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .transition(.scale.combined(with: .opacity))
            }
            
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24)
                
                Group {
                    if showPassword {
                        TextField("Password", text: $password, onEditingChanged: { focused in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isFocused = focused
                            }
                        })
                    } else {
                        SecureField("Password", text: $password, onCommit: {
                            isFocused = false
                        })
                        .onTapGesture {
                            isFocused = true
                        }
                    }
                }
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .textContentType(.password)
                .autocapitalization(.none)
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showPassword.toggle()
                    }
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(isFocused ? 0.15 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: isFocused ? [Color(hex: 0x667EEA), Color(hex: 0x764BA2)] : [.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: password)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - Social Button

struct SocialButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 64, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: 0x0F0C29),
                Color(hex: 0x302B63),
                Color(hex: 0x24243E)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Floating Particles

struct FloatingParticles: View {
    let particleCount = 20
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Particle(index: index)
            }
        }
        .ignoresSafeArea()
    }
}

struct Particle: View {
    let index: Int
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: 0x667EEA).opacity(0.3),
                        Color(hex: 0xF093FB).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: CGFloat.random(in: 20...60))
            .blur(radius: 10)
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                let delay = Double(index) * 0.1
                let duration = Double.random(in: 3...6)
                
                xOffset = CGFloat.random(in: -200...200)
                
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    yOffset = CGFloat.random(in: -300...300)
                    opacity = Double.random(in: 0.2...0.6)
                }
            }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Signing in...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
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
