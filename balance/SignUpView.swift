import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorText = ""
    
    var onSignIn: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 40)
                        
                        // Logo & Title
                        VStack(spacing: 12) {
                            Text("Balance")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: 0x667EEA),
                                            Color(hex: 0x96a8fa)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Create your account")
                                .font(DS.Typography.title)
                                .foregroundStyle(DS.Colors.text)
                        }
                        .padding(.bottom, 20)
                        
                        // Sign Up Form
                        DS.Card {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Get started with Balance")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)
                                
                                // Email
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Email")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                    
                                    TextField("your@email.com", text: $email)
                                        .textFieldStyle(DS.TextFieldStyle())
                                        .textContentType(.emailAddress)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                }
                                
                                // Password
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Password")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                    
                                    SecureField("At least 6 characters", text: $password)
                                        .textFieldStyle(DS.TextFieldStyle())
                                        .textContentType(.newPassword)
                                }
                                
                                // Confirm Password
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Confirm Password")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                    
                                    SecureField("Re-enter password", text: $confirmPassword)
                                        .textFieldStyle(DS.TextFieldStyle())
                                        .textContentType(.newPassword)
                                }
                                
                                // Password Requirements
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: password.count >= 6 ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(password.count >= 6 ? DS.Colors.positive : DS.Colors.subtext)
                                            .font(.caption)
                                        Text("At least 6 characters")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: password == confirmPassword && !password.isEmpty ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(password == confirmPassword && !password.isEmpty ? DS.Colors.positive : DS.Colors.subtext)
                                            .font(.caption)
                                        Text("Passwords match")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                }
                                
                                // Error Message
                                if showError {
                                    Text(errorText)
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.negative)
                                        .padding(.vertical, 4)
                                }
                                
                                if let error = authManager.errorMessage {
                                    Text(error)
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.negative)
                                        .padding(.vertical, 4)
                                }
                                
                                // Sign Up Button
                                Button {
                                    validateAndSignUp()
                                } label: {
                                    HStack {
                                        if authManager.isLoading {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "person.badge.plus.fill")
                                            Text("Create Account")
                                        }
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .disabled(!isFormValid || authManager.isLoading)
                            }
                        }
                        
                        // Sign In
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.subtext)
                            
                            Button {
                                onSignIn()
                            } label: {
                                Text("Sign in")
                                    .font(DS.Typography.body.weight(.semibold))
                                    .foregroundStyle(Color(hex: 0x667EEA))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        password.count >= 6 && 
        password == confirmPassword
    }
    
    private func validateAndSignUp() {
        showError = false
        errorText = ""
        
        guard password == confirmPassword else {
            showError = true
            errorText = "Passwords don't match"
            return
        }
        
        guard password.count >= 6 else {
            showError = true
            errorText = "Password must be at least 6 characters"
            return
        }
        
        Task {
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
                let trimmedPassword = password.trimmingCharacters(in: .whitespaces)
                try await authManager.signUp(email: trimmedEmail, password: trimmedPassword)
            } catch {
                showError = true
            }
        }
    }
}
