import SwiftUI
import FirebaseAuth

struct SimplePaywallView: View {
    @StateObject private var subscriptionManager = SimpleSubscriptionManager.shared
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var showingActivationCode = false
    @State private var activationCode = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - بهتر شده
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.02, green: 0.02, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Header - سایزها بهتر شده
                        VStack(spacing: 14) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.top, 30)
                            
                            Text("Balance Pro")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Unlock the full potential")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Features - کمپکت‌تر و بهتر
                        VStack(spacing: 16) {
                            FeatureRow(
                                icon: "infinity",
                                title: "Unlimited Transactions"
                            )
                            
                            FeatureRow(
                                icon: "chart.bar.fill",
                                title: "Advanced Analytics"
                            )
                            
                            FeatureRow(
                                icon: "icloud.fill",
                                title: "Cloud Sync"
                            )
                            
                            FeatureRow(
                                icon: "doc.text.fill",
                                title: "Export Reports"
                            )
                            
                            FeatureRow(
                                icon: "tray.and.arrow.down.fill",
                                title: "Import CSV"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Pricing Cards - بهتر شده
                        VStack(spacing: 10) {
                            PricingCard(
                                title: "Yearly",
                                price: "€49.99",
                                period: "per year",
                                badge: "BEST VALUE",
                                savings: "Save €9.89",
                                perMonth: "€4.17/month"
                            )
                            
                            PricingCard(
                                title: "Monthly",
                                price: "€4.99",
                                period: "per month",
                                badge: nil,
                                savings: nil,
                                perMonth: nil
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Purchase Buttons - سایزها بهتر شده
                        VStack(spacing: 14) {
                            Button {
                                if let url = URL(string: "https://giorastudio.gumroad.com/l/efzzxa") {
                                    openURL(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                    Text("Buy Subscription")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.black)
                                .cornerRadius(14)
                            }
                            
                            Button {
                                showingActivationCode = true
                            } label: {
                                HStack {
                                    Image(systemName: "key.fill")
                                    Text("Already Purchased? Activate")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Footer - کوچک‌تر
                        Text("You'll receive an activation code via email after purchase")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 30)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .alert("Activate Subscription", isPresented: $showingActivationCode) {
                TextField("Activation Code", text: $activationCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button("Cancel", role: .cancel) {
                    activationCode = ""
                }
                
                Button("Activate") {
                    Task {
                        await activateWithCode()
                    }
                }
            } message: {
                Text("Enter the activation code you received via email")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func activateWithCode() async {
        guard !activationCode.isEmpty else {
            errorMessage = "Please enter an activation code"
            showingError = true
            return
        }
        
        guard let userId = authManager.currentUser?.uid else {
            errorMessage = "User not signed in"
            showingError = true
            return
        }
        
        let type: SimpleSubscriptionManager.SubscriptionType
        
        switch activationCode.uppercased() {
        case "MONTHLY2024", "MONTHLY", "M":
            type = .monthly
        case "YEARLY2024", "YEARLY", "Y":
            type = .yearly
        default:
            errorMessage = "Invalid activation code"
            showingError = true
            return
        }
        
        await subscriptionManager.activateSubscription(userId: userId, type: type)
        
        activationCode = ""
        dismiss()
    }
}

// MARK: - Feature Row - کوچک‌تر و بهتر
struct FeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Pricing Card - بهتر شده
struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let badge: String?
    let savings: String?
    let perMonth: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Badge اگه داشت
            if let badge = badge {
                HStack {
                    Spacer()
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                }
            }
            
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let savings = savings {
                        Text(savings)
                            .font(.system(size: 13))
                            .foregroundColor(.green)
                    }
                    
                    if let perMonth = perMonth {
                        Text(perMonth)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text(price)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    Text(period)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(18)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(badge != nil ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            badge != nil ? Color.green.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: badge != nil ? 2 : 1
                        )
                )
        )
    }
}

// Helper for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    SimplePaywallView()
        .environmentObject(AuthManager())
}
