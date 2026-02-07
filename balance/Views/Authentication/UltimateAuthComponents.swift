import SwiftUI

// MARK: - Shared Components Namespace

enum UltimateAuthComponents {
    
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
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
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
    
    // MARK: - Animated Gradient Background
    struct AnimatedGradientBackground: View {
        var body: some View {
            LinearGradient(
                colors: [
                    Color(hex: 0x0a0a0a),  // Almost black
                    Color(hex: 0x1a1a1a),  // Dark gray
                    Color(hex: 0x0f0f0f)   // Very dark
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Floating Particles
    struct FloatingParticles: View {
        let particleCount = 15
        
        var body: some View {
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    FloatingParticle(index: index)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    struct FloatingParticle: View {
        let index: Int
        @State private var yOffset: CGFloat = 0
        @State private var xOffset: CGFloat = 0
        @State private var opacity: Double = 0
        
        var body: some View {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x667EEA).opacity(0.2),
                            Color(hex: 0xF093FB).opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: CGFloat.random(in: 20...50))
                .blur(radius: 8)
                .offset(x: xOffset, y: yOffset)
                .opacity(opacity)
                .onAppear {
                    let delay = Double(index) * 0.15
                    let duration = Double.random(in: 4...7)
                    
                    xOffset = CGFloat.random(in: -150...150)
                    
                    withAnimation(
                        .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                    ) {
                        yOffset = CGFloat.random(in: -250...250)
                        opacity = Double.random(in: 0.3...0.6)
                    }
                }
        }
    }
    
    // MARK: - Social Button
    struct SocialAuthButton: View {
        let icon: String
        let color: Color
        let action: () -> Void
        @State private var isPressed = false
        
        var body: some View {
            Button {
                action()
            } label: {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
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
    
    // MARK: - Loading Overlay
    struct AuthLoadingOverlay: View {
        let message: String
        
        var body: some View {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(.white)
                    
                    Text(message)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }
    
    // MARK: - Floating Label TextField
    struct FloatingTextField: View {
        @Binding var text: String
        let placeholder: String
        let icon: String
        var keyboardType: UIKeyboardType = .default
        var isSecure: Bool = false
        @Binding var showSecure: Bool
        @State private var isFocused = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                if !text.isEmpty || isFocused {
                    Text(placeholder)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .transition(.scale.combined(with: .opacity))
                }
                
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 20)
                    
                    Group {
                        if isSecure && !showSecure {
                            SecureField(placeholder, text: $text)
                                .onTapGesture { isFocused = true }
                        } else {
                            TextField(placeholder, text: $text)
                                .onChange(of: text) { _, _ in
                                    if !isFocused { isFocused = true }
                                }
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .textContentType(keyboardType == .emailAddress ? .emailAddress : (isSecure ? .password : .none))
                    
                    if isSecure {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showSecure.toggle()
                            }
                        } label: {
                            Image(systemName: showSecure ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(isFocused ? 0.12 : 0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: isFocused ? [Color(hex: 0x667EEA), Color(hex: 0x764BA2)] : [.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                )
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        }
    }
    
    // MARK: - Gradient Button
    struct GradientButton: View {
        let title: String
        let icon: String
        let isLoading: Bool
        let isEnabled: Bool
        let action: () -> Void
        
        var body: some View {
            Button {
                action()
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x667EEA), Color(hex: 0x764BA2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .cornerRadius(14)
                .shadow(
                    color: Color(hex: 0x667EEA).opacity(isEnabled ? 0.4 : 0.2),
                    radius: 15,
                    x: 0,
                    y: 8
                )
            }
            .disabled(!isEnabled || isLoading)
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
        }
    }
}
