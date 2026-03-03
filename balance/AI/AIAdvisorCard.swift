// ==========================================
// AI Advisor Card
// ==========================================

import SwiftUI

struct AIAdvisorCard: View {
    @Binding var store: Store
    @State private var showAIChat = false
    
    var body: some View {
        Button {
            showAIChat = true
            Haptics.medium()
        } label: {
            DS.Card {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.Colors.accent.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DS.Colors.accent)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("AI Financial Advisor")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.Colors.text)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DS.Colors.subtext)
                        }
                        
                        Text("Personalized insights & advice")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(DS.Colors.subtext)
                        
                        // Feature tags
                        HStack(spacing: 6) {
                            FeatureTag(icon: "chart.bar.fill", text: "Analysis")
                            FeatureTag(icon: "lightbulb.fill", text: "Tips")
                            FeatureTag(icon: "message.fill", text: "Chat")
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAIChat) {
            AIFinancialAdvisorView(store: $store)
        }
    }
}

struct FeatureTag: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(DS.Colors.subtext)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DS.Colors.surface2, in: Capsule())
    }
}
