import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showError = false
    @State private var errorText = ""
    
    var onSignIn: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)
                        
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
                        .padding(.bottom, 8)
                        
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
                                    
                                    HStack(spacing: 0) {
                                        Group {
                                            if showPassword {
                                                TextField("At least 6 characters", text: $password)
                                            } else {
                                                SecureField("At least 6 characters", text: $password)
                                            }
                                        }
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                showPassword.toggle()
                                            }
                                        } label: {
                                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(DS.Colors.subtext)
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(DS.Colors.grid, lineWidth: 1)
                                    )
                                }
                                
                                // Confirm Password
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Confirm Password")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                    
                                    HStack(spacing: 0) {
                                        Group {
                                            if showConfirmPassword {
                                                TextField("Re-enter password", text: $confirmPassword)
                                            } else {
                                                SecureField("Re-enter password", text: $confirmPassword)
                                            }
                                        }
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                showConfirmPassword.toggle()
                                            }
                                        } label: {
                                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(DS.Colors.subtext)
                                                .frame(width: 44, height: 44)
                                                .contentShape(Rectangle())
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(DS.Colors.grid, lineWidth: 1)
                                    )
                                }
                                
                                // Password Requirements + Strength
                                VStack(alignment: .leading, spacing: 8) {
                                    // Strength Bar
                                    if !password.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text("Password Strength:")
                                                    .font(DS.Typography.caption)
                                                    .foregroundStyle(DS.Colors.subtext)
                                                
                                                Text(passwordStrengthText)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundStyle(passwordStrengthColor)
                                            }
                                            
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(DS.Colors.surface2)
                                                    
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(passwordStrengthColor)
                                                        .frame(width: geo.size.width * passwordStrength)
                                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: passwordStrength)
                                                }
                                            }
                                            .frame(height: 6)
                                        }
                                    }
                                    
                                    // Requirements
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
    
    // MARK: - Password Strength
    
    private var passwordStrength: Double {
        let length = password.count
        var strength = 0.0
        
        if length >= 6 { strength += 0.25 }
        if length >= 8 { strength += 0.25 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { strength += 0.15 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { strength += 0.15 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 0.1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { strength += 0.1 }
        
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
