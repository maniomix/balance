import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "chart.bar.fill",
                        iconColor: Color(hexValue: 0x667EEA),
                        title: "Track Your Finances",
                        description: "Effortlessly monitor your income, expenses, and budget in one place."
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "sparkles",
                        iconColor: Color(hexValue: 0xFF9F0A),
                        title: "Smart Insights",
                        description: "Get AI-powered analysis and recommendations to improve your financial health."
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "icloud.fill",
                        iconColor: Color(hexValue: 0x3498DB),
                        title: "Sync Everywhere",
                        description: "Your data syncs seamlessly across all your devices with secure cloud backup."
                    )
                    .tag(2)
                    
                    OnboardingPage(
                        icon: "lock.shield.fill",
                        iconColor: Color(hexValue: 0x2ED573),
                        title: "Privacy First",
                        description: "Your financial data is encrypted and stays private. We never see your information."
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == currentPage ? Color(hexValue: 0x667EEA) : Color(uiColor: .tertiaryLabel))
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)
                
                // Buttons
                VStack(spacing: 12) {
                    if currentPage == 3 {
                        // Get Started Button
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                hasCompletedOnboarding = true
                            }
                        } label: {
                            Text("Get Started")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hexValue: 0x667EEA))
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                    } else {
                        // Next Button
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } label: {
                            Text("Next")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hexValue: 0x667EEA))
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    // Skip Button
                    if currentPage < 3 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                hasCompletedOnboarding = true
                            }
                        } label: {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(uiColor: .secondaryLabel))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Onboarding Page

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(iconColor)
            }
            
            VStack(spacing: 16) {
                // Title
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(uiColor: .label))
                    .multilineTextAlignment(.center)
                
                // Description
                Text(description)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
