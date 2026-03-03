// ==========================================
// AI Insights Manager - با Gemini API رایگان
// ==========================================

import Foundation
import SwiftUI
import Combine

@MainActor
class AIInsightsManager: ObservableObject {
    static let shared = AIInsightsManager()
    
    @Published var isGenerating = false
    @Published var lastInsight: AIInsight?
    @Published var error: String?
    
    private let apiKey = "AIzaSyBgEm09l6jxvazkGmwMOztAnku7DgeIUi0" // ← API key خودت (رایگان!)
    private let apiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"
    
    private init() {}
    
    // MARK: - Generate AI Insights
    
    func generateInsights(for store: Store) async throws -> AIInsight {
        isGenerating = true
        defer { isGenerating = false }
        
        // 1. آماده کردن data برای Gemini
        let prompt = buildPrompt(from: store)
        
        // 2. صدا زدن Gemini API
        let response = try await callGeminiAPI(prompt: prompt)
        
        // 3. Parse کردن response
        let insight = parseResponse(response)
        
        await MainActor.run {
            lastInsight = insight
        }
        
        return insight
    }
    
    // MARK: - Generate Chat Response (for conversational AI)
    
    func generateChatResponse(prompt: String) async throws -> String {
        print("💬 Generating chat response...")
        
        // Call Gemini API with custom prompt
        let response = try await callGeminiAPI(prompt: prompt)
        
        return response
    }
    
    // MARK: - Build Prompt
    
    private func buildPrompt(from store: Store) -> String {
        let budget = Double(store.budgetTotal) / 100.0
        let spent = Double(store.spent(for: store.selectedMonth)) / 100.0
        let remaining = Double(store.remaining(for: store.selectedMonth)) / 100.0
        let income = Double(store.income(for: store.selectedMonth)) / 100.0
        
        // Category breakdown (for selected month)
        let calendar = Calendar.current
        let monthTransactions = store.transactions.filter {
            calendar.isDate($0.date, equalTo: store.selectedMonth, toGranularity: .month)
        }
        
        var categoryBreakdown = ""
        for category in store.allCategories {
            let categorySpent = monthTransactions
                .filter { $0.category == category && $0.type == .expense }
                .reduce(0) { $0 + $1.amount }
            
            if categorySpent > 0 {
                let amount = Double(categorySpent) / 100.0
                let cap = Double(store.categoryBudget(for: category)) / 100.0
                categoryBreakdown += "- \(category.title): €\(String(format: "%.2f", amount))"
                if cap > 0 {
                    categoryBreakdown += " / €\(String(format: "%.2f", cap)) cap"
                }
                categoryBreakdown += "\n"
            }
        }
        
        // Recent transactions (for selected month)
        let recentTx = monthTransactions
            .filter { $0.type == .expense }
            .sorted { $0.date > $1.date }
            .prefix(10)
        
        var recentList = ""
        for tx in recentTx {
            let amount = Double(tx.amount) / 100.0
            recentList += "- €\(String(format: "%.2f", amount)) on \(tx.category.title)"
            if !tx.note.isEmpty {
                recentList += " (\(tx.note))"
            }
            recentList += "\n"
        }
        
        let today = calendar.component(.day, from: Date())
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        let daysRemaining = max(0, daysInMonth - today)
        
        return """
        You are a financial advisor analyzing a user's spending for the current month.
        
        BUDGET OVERVIEW:
        - Monthly Budget: €\(String(format: "%.2f", budget))
        - Total Income: €\(String(format: "%.2f", income))
        - Total Spent: €\(String(format: "%.2f", spent))
        - Remaining: €\(String(format: "%.2f", remaining))
        - Days into month: \(today) / \(daysInMonth)
        - Days remaining: \(daysRemaining)
        
        CATEGORY BREAKDOWN:
        \(categoryBreakdown)
        
        RECENT TRANSACTIONS:
        \(recentList)
        
        Please provide:
        1. A brief assessment of their financial health (2-3 sentences)
        2. One specific actionable recommendation
        3. One insight about their spending patterns
        4. A motivational message if they're doing well, or encouragement if struggling
        
        Be concise, friendly, and Persian-friendly (use simple English that translates well).
        Focus on practical advice, not generic tips.
        
        Format your response as JSON:
        {
            "assessment": "...",
            "recommendation": "...",
            "insight": "...",
            "message": "..."
        }
        """
    }
    
    // MARK: - Call Gemini API
    
    private func callGeminiAPI(prompt: String) async throws -> String {
        // Build URL with API key
        guard var urlComponents = URLComponents(string: apiURL) else {
            throw AIError.invalidResponse
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            throw AIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Gemini API Error: \(errorText)")
            throw AIError.apiError(httpResponse.statusCode, errorText)
        }
        
        // Parse Gemini response
        struct GeminiResponse: Codable {
            let candidates: [Candidate]
            struct Candidate: Codable {
                let content: Content
                struct Content: Codable {
                    let parts: [Part]
                    struct Part: Codable {
                        let text: String
                    }
                }
            }
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw AIError.emptyResponse
        }
        
        return text
    }
    
    // MARK: - Parse Response
    
    private func parseResponse(_ text: String) -> AIInsight {
        // Try to extract JSON from response
        if let jsonStart = text.range(of: "{"),
           let jsonEnd = text.range(of: "}", options: .backwards) {
            let jsonString = String(text[jsonStart.lowerBound...jsonEnd.upperBound])
            
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONDecoder().decode(AIInsightResponse.self, from: data) {
                return AIInsight(
                    assessment: json.assessment,
                    recommendation: json.recommendation,
                    insight: json.insight,
                    message: json.message,
                    generatedAt: Date()
                )
            }
        }
        
        // Fallback: use raw text
        return AIInsight(
            assessment: text,
            recommendation: "",
            insight: "",
            message: "",
            generatedAt: Date()
        )
    }
}

// MARK: - Models

struct AIInsight: Codable, Identifiable {
    let id = UUID()
    let assessment: String
    let recommendation: String
    let insight: String
    let message: String
    let generatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case assessment, recommendation, insight, message, generatedAt
    }
}

private struct AIInsightResponse: Codable {
    let assessment: String
    let recommendation: String
    let insight: String
    let message: String
}

enum AIError: LocalizedError {
    case invalidResponse
    case apiError(Int, String)
    case emptyResponse
    case invalidAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI service"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .emptyResponse:
            return "Empty response from AI"
        case .invalidAPIKey:
            return "Invalid API key"
        }
    }
}

// ==========================================
// AI Insights View Component
// ==========================================

struct AIInsightsCard: View {
    @Binding var store: Store
    @StateObject private var aiManager = AIInsightsManager.shared
    
    var body: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("AI Insights")
                        .font(DS.Typography.section)
                        .foregroundStyle(DS.Colors.text)
                    
                    Spacer()
                    
                    if aiManager.isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button {
                            Task {
                                do {
                                    _ = try await aiManager.generateInsights(for: store)
                                    Haptics.success()
                                } catch {
                                    print("❌ AI Error: \(error)")
                                    Haptics.error()
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DS.Colors.text)
                        }
                    }
                }
                
                if let insight = aiManager.lastInsight {
                    VStack(alignment: .leading, spacing: 12) {
                        // Assessment
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Assessment", systemImage: "chart.bar.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DS.Colors.subtext)
                            
                            Text(insight.assessment)
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.text)
                        }
                        
                        Divider()
                        
                        // Recommendation
                        if !insight.recommendation.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Action", systemImage: "lightbulb.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.orange)
                                
                                Text(insight.recommendation)
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.text)
                            }
                        }
                        
                        // Insight
                        if !insight.insight.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Pattern", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.blue)
                                
                                Text(insight.insight)
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.text)
                            }
                        }
                        
                        // Message
                        if !insight.message.isEmpty {
                            Text(insight.message)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding(.top, 4)
                        }
                        
                        // Timestamp
                        Text("Generated \(timeAgo(insight.generatedAt))")
                            .font(.system(size: 10))
                            .foregroundStyle(DS.Colors.subtext)
                            .padding(.top, 4)
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(DS.Colors.subtext.opacity(0.5))
                        
                        Text("Get AI-powered insights")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.subtext)
                        
                        Button {
                            Task {
                                do {
                                    _ = try await aiManager.generateInsights(for: store)
                                    Haptics.success()
                                } catch {
                                    print("❌ AI Error: \(error)")
                                    Haptics.error()
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Generate Insights")
                            }
                        }
                        .buttonStyle(DS.PrimaryButton())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                
                if let error = aiManager.error {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
