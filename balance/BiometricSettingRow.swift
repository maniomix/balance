import SwiftUI

struct BiometricSettingRow: View {
    @StateObject private var biometricManager = BiometricAuthManager()
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var showEnableSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isEnabling = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with toggle
            HStack(alignment: .center, spacing: 12) {
                // Icon
                Image(systemName: biometricManager.biometricIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(DS.Colors.text)
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(biometricManager.biometricName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.text)
                    
                    Text(statusText)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.subtext)
                }
                
                Spacer()
                
                // Toggle
                Toggle("", isOn: Binding(
                    get: { biometricManager.isBiometricEnabled },
                    set: { newValue in
                        if newValue {
                            showEnableSheet = true
                        } else {
                            biometricManager.disableBiometric()
                        }
                    }
                ))
                .disabled(!biometricManager.isBiometricAvailable())
            }
            
            // Description
            if biometricManager.isBiometricAvailable() {
                Text("Sign in quickly and securely using \(biometricManager.biometricName) instead of entering your password every time.")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.subtext.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $showEnableSheet) {
            EnableBiometricSheet(
                biometricManager: biometricManager,
                email: $email,
                password: $password,
                isEnabling: $isEnabling,
                showError: $showError,
                errorMessage: $errorMessage
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var statusText: String {
        if !biometricManager.isBiometricAvailable() {
            return "Not available"
        } else if biometricManager.isBiometricEnabled {
            return "Enabled"
        } else {
            return "Disabled"
        }
    }
}

// MARK: - Enable Biometric Sheet

struct EnableBiometricSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @ObservedObject var biometricManager: BiometricAuthManager
    
    @Binding var email: String
    @Binding var password: String
    @Binding var isEnabling: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: biometricManager.biometricIcon)
                                .font(.system(size: 56))
                                .foregroundStyle(DS.Colors.text)
                            
                            VStack(spacing: 8) {
                                Text("Enable \(biometricManager.biometricName)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(DS.Colors.text)
                                
                                Text("Sign in quickly and securely with \(biometricManager.biometricName)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(DS.Colors.subtext)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 32)
                        
                        // Info Card
                        DS.Card {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Secure & Private")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(DS.Colors.text)
                                    
                                    Text("Your credentials are encrypted and stored securely on your device only.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DS.Colors.subtext)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 20)
                        
                        // Credentials Form
                        VStack(spacing: 20) {
                            Text("Verify Your Identity")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(DS.Colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                TextField("your@email.com", text: $email)
                                    .textFieldStyle(DS.TextFieldStyle())
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .password
                                    }
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                HStack(spacing: 0) {
                                    Group {
                                        if showPassword {
                                            TextField("Enter your password", text: $password)
                                        } else {
                                            SecureField("Enter your password", text: $password)
                                        }
                                    }
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        if !email.isEmpty && !password.isEmpty {
                                            enableBiometric()
                                        }
                                    }
                                    
                                    Button {
                                        showPassword.toggle()
                                    } label: {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(DS.Colors.subtext)
                                            .frame(width: 40, height: 40)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(DS.Colors.grid, lineWidth: 1)
                                )
                            }
                            
                            // Enable Button
                            Button {
                                enableBiometric()
                            } label: {
                                HStack(spacing: 8) {
                                    if isEnabling {
                                        ProgressView()
                                            .tint(.black)
                                            .scaleEffect(0.9)
                                    } else {
                                        Image(systemName: biometricManager.biometricIcon)
                                            .font(.system(size: 16))
                                        Text("Enable \(biometricManager.biometricName)")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(email.isEmpty || password.isEmpty || isEnabling ? Color.gray.opacity(0.3) : DS.Colors.text)
                                .foregroundStyle(email.isEmpty || password.isEmpty || isEnabling ? DS.Colors.subtext : DS.Colors.bg)
                                .cornerRadius(12)
                            }
                            .disabled(email.isEmpty || password.isEmpty || isEnabling)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DS.Colors.text)
                }
            }
        }
    }
    
    private func enableBiometric() {
        focusedField = nil
        isEnabling = true
        
        Task {
            do {
                // Verify credentials first
                try await authManager.signIn(
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password.trimmingCharacters(in: .whitespaces)
                )
                
                // Enable biometric
                try await biometricManager.enableBiometric(
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password.trimmingCharacters(in: .whitespaces)
                )
                
                await MainActor.run {
                    isEnabling = false
                    dismiss()
                }
                
            } catch let error as BiometricError {
                await MainActor.run {
                    isEnabling = false
                    errorMessage = error.errorDescription ?? "Failed to enable biometric"
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isEnabling = false
                    errorMessage = "Invalid email or password. Please try again."
                    showError = true
                }
            }
        }
    }
}
