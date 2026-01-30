import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showResetSuccess = false
    
    var onSignUp: () -> Void
    
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
                            
                            Text("Welcome back")
                                .font(DS.Typography.title)
                                .foregroundStyle(DS.Colors.text)
                        }
                        .padding(.bottom, 20)
                        
                        // Login Form
                        DS.Card {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Sign in to your account")
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
                                    
                                    SecureField("••••••••", text: $password)
                                        .textFieldStyle(DS.TextFieldStyle())
                                        .textContentType(.password)
                                }
                                
                                // Forgot Password
                                Button {
                                    resetEmail = email
                                    showForgotPassword = true
                                } label: {
                                    Text("Forgot password?")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(Color(hex: 0x667EEA))
                                }
                                
                                // Error Message
                                if let error = authManager.errorMessage {
                                    Text(error)
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.negative)
                                        .padding(.vertical, 4)
                                }
                                
                                // Sign In Button
                                Button {
                                    Task {
                                        do {
                                            let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
                                            let trimmedPassword = password.trimmingCharacters(in: .whitespaces)
                                            try await authManager.signIn(email: trimmedEmail, password: trimmedPassword)
                                        } catch {
                                            showError = true
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if authManager.isLoading {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "arrow.right.circle.fill")
                                            Text("Sign In")
                                        }
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                            }
                        }
                        
                        // Sign Up
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.subtext)
                            
                            Button {
                                onSignUp()
                            } label: {
                                Text("Sign up")
                                    .font(DS.Typography.body.weight(.semibold))
                                    .foregroundStyle(Color(hex: 0x667EEA))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .sheet(isPresented: $showForgotPassword) {
                forgotPasswordSheet
            }
        }
    }
    
    private var forgotPasswordSheet: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    DS.Card {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reset Password")
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)
                            
                            Text("Enter your email and we'll send you a link to reset your password.")
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.subtext)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                TextField("your@email.com", text: $resetEmail)
                                    .textFieldStyle(DS.TextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            
                            if let error = authManager.errorMessage {
                                Text(error)
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.negative)
                            }
                            
                            Button {
                                Task {
                                    do {
                                        try await authManager.resetPassword(email: resetEmail)
                                        showResetSuccess = true
                                    } catch {}
                                }
                            } label: {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "envelope.fill")
                                        Text("Send Reset Link")
                                    }
                                }
                            }
                            .buttonStyle(DS.PrimaryButton())
                            .disabled(resetEmail.isEmpty || authManager.isLoading)
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        showForgotPassword = false
                    }
                    .foregroundStyle(DS.Colors.subtext)
                }
            }
            .alert("Reset Link Sent", isPresented: $showResetSuccess) {
                Button("OK") {
                    showForgotPassword = false
                }
            } message: {
                Text("Check your email for instructions to reset your password.")
            }
        }
    }
}
