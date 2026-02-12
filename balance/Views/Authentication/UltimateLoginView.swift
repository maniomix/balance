import SwiftUI
import FirebaseAuth

struct UltimateLoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var googleSignInManager = GoogleSignInManager()
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showResetSuccess = false
    @State private var showSocialError = false
    @State private var socialErrorMessage = ""
    
    var onSignUp: () -> Void
    
    var body: some View {
        ZStack {
            // Background - Same as App
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    
                    // Logo
                    logoSection
                        .padding(.bottom, 32)
                    
                    // Login Card
                    loginCard
                        .padding(.horizontal, 20)
                    
                    // Forgot Password
                    forgotPasswordButton
                        .padding(.top, 16)
                    
                    // Divider
                    orDivider
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                    
                    // Social Login
                    socialButtons
                        .padding(.horizontal, 20)
                    
                    // Sign Up Link
                    signUpLink
                        .padding(.top, 32)
                    
                    Spacer().frame(height: 40)
                }
            }
            
            if isLoading {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
        .alert("Password Reset", isPresented: $showResetSuccess) {
            Button("OK") { }
        } message: {
            Text("Password reset email sent. Check your inbox.")
        }
        .alert("Sign In Error", isPresented: $showSocialError) {
            Button("OK") { }
        } message: {
            Text(socialErrorMessage)
        }
    }
    
    // MARK: - Logo
    
    private var logoSection: some View {
        VStack(spacing: 10) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(uiColor: .label))
            }
            
            Text("Balance")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(uiColor: .label))
            
            Text("Welcome back")
                .font(.system(size: 14))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
    }
    
    // MARK: - Login Card
    
    private var loginCard: some View {
        VStack(spacing: 16) {
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(uiColor: .label))
                
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .frame(width: 20)
                    
                    TextField("your@email.com", text: $email)
                        .font(.system(size: 16))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(uiColor: .separator), lineWidth: 1)
                )
            }
            
            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(uiColor: .label))
                
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .frame(width: 20)
                    
                    if showPassword {
                        TextField("Enter password", text: $password)
                            .font(.system(size: 16))
                            .textContentType(.password)
                    } else {
                        SecureField("Enter password", text: $password)
                            .font(.system(size: 16))
                            .textContentType(.password)
                    }
                    
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(uiColor: .separator), lineWidth: 1)
                )
            }
            
            // Error Message
            if let error = authManager.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Sign In Button
            Button {
                signIn()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(Color(uiColor: .systemBackground))
                    } else {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(uiColor: .label))
                .foregroundStyle(Color(uiColor: .systemBackground))
                .cornerRadius(12)
            }
            .disabled(isLoading || !isFormValid)
            .opacity(isFormValid ? 1.0 : 0.5)
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
    }
    
    // MARK: - Forgot Password
    
    private var forgotPasswordButton: some View {
        Button {
            showForgotPassword = true
        } label: {
            Text("Forgot password?")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hexValue: 0x667EEA))
        }
    }
    
    // MARK: - Divider
    
    private var orDivider: some View {
        HStack {
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 1)
            
            Text("OR")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.horizontal, 12)
            
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 1)
        }
    }
    
    // MARK: - Social Buttons
    
    private var socialButtons: some View {
        VStack(spacing: 10) {
            // Google Sign In
            Button {
                signInWithGoogle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    
                    Text("Continue with Google")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(uiColor: .secondarySystemBackground))
                .foregroundStyle(Color(uiColor: .label))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(uiColor: .separator), lineWidth: 1)
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
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                Text("Sign Up")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hexValue: 0x667EEA))
            }
            .font(.system(size: 14))
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text("Signing in...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Forgot Password Sheet
    
    private var forgotPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hexValue: 0x667EEA).opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color(hexValue: 0x667EEA))
                }
                .padding(.top, 20)
                
                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(uiColor: .label))
                    
                    Text("Enter your email to receive reset instructions")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(uiColor: .label))
                    
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                        
                        TextField("your@email.com", text: $resetEmail)
                            .font(.system(size: 16))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(uiColor: .separator), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                
                // Send Button
                Button {
                    sendPasswordReset()
                } label: {
                    Text("Send Reset Link")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hexValue: 0x667EEA))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .disabled(resetEmail.isEmpty)
                .opacity(resetEmail.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showForgotPassword = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private var isFormValid: Bool {
        !email.isEmpty && password.count >= 6
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
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
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
    
    private func sendPasswordReset() {
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: resetEmail.trimmingCharacters(in: .whitespaces).lowercased())
                
                await MainActor.run {
                    showForgotPassword = false
                    showResetSuccess = true
                    resetEmail = ""
                }
            } catch {
                await MainActor.run {
                    socialErrorMessage = "Failed to send reset email. Please check the email address."
                    showSocialError = true
                }
            }
        }
    }
}
