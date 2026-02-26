// ==========================================
// AI Advisor Card - برای InsightsView
// وقتی کلیک میشه → صفحه چت باز میشه
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
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("AI Financial Advisor")
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DS.Colors.subtext)
                        }
                        
                        Text("Get personalized insights and advice")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.subtext)
                            .lineLimit(2)
                        
                        // Features
                        HStack(spacing: 16) {
                            FeatureTag(icon: "chart.bar.fill", text: "Analysis")
                            FeatureTag(icon: "lightbulb.fill", text: "Tips")
                            FeatureTag(icon: "message.fill", text: "Chat")
                        }
                        .padding(.top, 4)
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
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(DS.Colors.subtext)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(DS.Colors.surface2)
        )
    }
}

// ==========================================
// استفاده در InsightsView:
// ==========================================

/*
در InsightsView، جایگزین کن AIInsightsCard با این:

VStack(spacing: 14) {
    // ✅ AI Advisor Card
    AIAdvisorCard(store: $store)
    
    // بقیه cards...
    DS.Card {
        // Analytical Report
    }
}
*/
