import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: Product?
    @State private var showingError = false
    @State private var isPurchasing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.top, 40)
                            
                            Text("Balance Pro")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Unlock the full potential of Balance")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Features
                        VStack(spacing: 20) {
                            FeatureRow(
                                icon: "infinity",
                                title: "Unlimited Transactions",
                                description: "Track as many transactions as you want"
                            )
                            
                            FeatureRow(
                                icon: "chart.bar.fill",
                                title: "Advanced Analytics",
                                description: "Deep insights into your spending patterns"
                            )
                            
                            FeatureRow(
                                icon: "icloud.fill",
                                title: "Cloud Sync",
                                description: "Access your data across all devices"
                            )
                            
                            FeatureRow(
                                icon: "doc.text.fill",
                                title: "Export Reports",
                                description: "Generate PDF and Excel reports anytime"
                            )
                            
                            FeatureRow(
                                icon: "bell.badge.fill",
                                title: "Smart Notifications",
                                description: "Get alerts for budgets and spending"
                            )
                            
                            FeatureRow(
                                icon: "lock.fill",
                                title: "Privacy First",
                                description: "Your data stays private and secure"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Subscription Options
                        if subscriptionManager.products.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(subscriptionManager.products, id: \.id) { product in
                                    SubscriptionOptionCard(
                                        product: product,
                                        isSelected: selectedProduct?.id == product.id,
                                        onTap: { selectedProduct = product }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Purchase Button
                        if let product = selectedProduct {
                            VStack(spacing: 12) {
                                Button {
                                    Task {
                                        await purchaseProduct(product)
                                    }
                                } label: {
                                    HStack {
                                        if isPurchasing {
                                            ProgressView()
                                                .tint(.black)
                                        } else {
                                            Text("Start Free Trial")
                                                .font(.system(size: 18, weight: .semibold))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.black)
                                    .cornerRadius(16)
                                }
                                .disabled(isPurchasing)
                                
                                Button {
                                    Task {
                                        await subscriptionManager.restorePurchases()
                                    }
                                } label: {
                                    Text("Restore Purchases")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Terms
                        HStack(spacing: 16) {
                            Link("Terms of Service", destination: URL(string: "https://yourwebsite.com/terms")!)
                            Text("•")
                            Link("Privacy Policy", destination: URL(string: "https://yourwebsite.com/privacy")!)
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .alert("Purchase Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptionManager.errorMessage ?? "Unknown error occurred")
            }
        }
        .onAppear {
            if selectedProduct == nil {
                selectedProduct = subscriptionManager.products.first
            }
        }
    }
    
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        
        do {
            let transaction = try await subscriptionManager.purchase(product)
            if transaction != nil {
                dismiss()
            }
        } catch {
            showingError = true
        }
        
        isPurchasing = false
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
}

// MARK: - Subscription Option Card
struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void
    
    private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if product.id.contains("yearly") {
                            Text("BEST VALUE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(product.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("per \(subscriptionManager.subscriptionPeriod(for: product))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) : LinearGradient(
                                    colors: [.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
        }
    }
}

#Preview {
    PaywallView()
}
