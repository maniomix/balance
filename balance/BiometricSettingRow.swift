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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: biometricManager.biometricIcon)
                            .foregroundStyle(DS.Colors.text)
                        Text(biometricManager.biometricName)
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.text)
                    }
                    
                    if !biometricManager.isBiometricAvailable() {
                        Text("Not available on this device")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                    }
                }
                
                Spacer()
                
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
            
            if biometricManager.isBiometricEnabled {
                Text("You can sign in using \(biometricManager.biometricName)")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Info
                        VStack(spacing: 12) {
                            Image(systemName: biometricManager.biometricIcon)
                                .font(.system(size: 60))
                                .foregroundStyle(DS.Colors.text)
                            
                            Text("Enable \(biometricManager.biometricName)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(DS.Colors.text)
                            
                            Text("Sign in quickly and securely with \(biometricManager.biometricName). Your credentials will be stored securely on your device.")
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.subtext)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 40)
                        
                        // Credentials Form
                        DS.Card {
                            VStack(spacing: 16) {
                                Text("Verify your identity")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)
                                
                                Divider().overlay(DS.Colors.grid)
                                
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
                                                TextField("Password", text: $password)
                                            } else {
                                                SecureField("Password", text: $password)
                                            }
                                        }
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        
                                        Button {
                                            showPassword.toggle()
                                        } label: {
                                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(DS.Colors.subtext)
                                                .frame(width: 44, height: 44)
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
                                
                                // Enable Button
                                Button {
                                    enableBiometric()
                                } label: {
                                    HStack {
                                        if isEnabling {
                                            ProgressView().tint(.black)
                                        } else {
                                            Text("Enable \(biometricManager.biometricName)")
                                        }
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .disabled(email.isEmpty || password.isEmpty || isEnabling)
                            }
                            .padding(20)
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
                }
            }
        }
    }
    
    private func enableBiometric() {
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
                    errorMessage = "Invalid email or password"
                    showError = true
                }
            }
        }
    }
}
