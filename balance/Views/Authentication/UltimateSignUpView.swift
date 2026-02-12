import SwiftUI
import FirebaseAuth

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
            // Background - Same as App
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)
                    
                    // Logo
                    logoSection
                        .padding(.bottom, 32)
                    
                    // SignUp Card
                    signUpCard
                        .padding(.horizontal, 20)
                    
                    // Divider
                    orDivider
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                    
                    // Social SignUp
                    socialButtons
                        .padding(.horizontal, 20)
                    
                    // Sign In Link
                    signInLink
                        .padding(.top, 32)
                    
                    Spacer().frame(height: 40)
                }
            }
            
            if isLoading {
                loadingOverlay
            }
        }
        .alert("Sign Up Error", isPresented: $showSocialError) {
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
            
            Text("Create your account")
                .font(.system(size: 14))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
    }
    
    // MARK: - SignUp Card
    
    private var signUpCard: some View {
        VStack(spacing: 16) {
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(uiColor: .label))
                
                HStack(spacing: 12) {
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
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .frame(width: 20)
                    
                    if showPassword {
                        TextField("At least 6 characters", text: $password)
                            .font(.system(size: 16))
                            .textContentType(.newPassword)
                    } else {
                        SecureField("At least 6 characters", text: $password)
                            .font(.system(size: 16))
                            .textContentType(.newPassword)
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
            
            // Confirm Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(uiColor: .label))
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .frame(width: 20)
                    
                    if showConfirmPassword {
                        TextField("Re-enter password", text: $confirmPassword)
                            .font(.system(size: 16))
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Re-enter password", text: $confirmPassword)
                            .font(.system(size: 16))
                            .textContentType(.newPassword)
                    }
                    
                    Button {
                        showConfirmPassword.toggle()
                    } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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
            
            // Password Requirements
            if !password.isEmpty {
                passwordValidation
            }
            
            // Error Messages
            if showError {
                Text(errorText)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.scale.combined(with: .opacity))
            }
            
            if let error = authManager.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Create Account Button
            Button {
                signUp()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(Color(uiColor: .systemBackground))
                    } else {
                        Text("Create Account")
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
    
    // MARK: - Password Validation
    
    private var passwordValidation: some View {
        VStack(alignment: .leading, spacing: 8) {
            requirementRow(
                met: password.count >= 6,
                text: "At least 6 characters"
            )
            
            requirementRow(
                met: password == confirmPassword && !password.isEmpty && !confirmPassword.isEmpty,
                text: "Passwords match"
            )
        }
    }
    
    private func requirementRow(met: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(met ? .green : Color(uiColor: .tertiaryLabel))
            
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
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
        VStack(spacing: 12) {
            // Google Sign Up
            Button {
                signUpWithGoogle()
            } label: {
                HStack(spacing: 12) {
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
    
    // MARK: - Sign In Link
    
    private var signInLink: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                onSignIn()
            }
        } label: {
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                Text("Sign In")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hexValue: 0x667EEA))
            }
            .font(.system(size: 15))
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
                
                Text("Creating account...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    // MARK: - Actions
    
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
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    socialErrorMessage = "Google Sign Up failed. Please try again."
                    showSocialError = true
                }
            }
        }
    }
}
