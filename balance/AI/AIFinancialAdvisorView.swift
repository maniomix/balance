// ==========================================
// AI Financial Advisor View
// صفحه جداگانه برای چت با AI
// ==========================================

import SwiftUI

struct AIFinancialAdvisorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var store: Store
    @StateObject private var aiManager = AIInsightsManager.shared
    
    @State private var chatMessages: [ChatMessage] = []
    @State private var userInput: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var isGenerating = false
    
    // Suggested questions
    private let suggestions = [
        "How can I reduce my spending?",
        "What's my biggest expense category?",
        "Am I on track with my budget?",
        "Tips to save more money?",
        "Analyze my spending pattern",
        "Where should I cut costs?"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                // Welcome message
                                if chatMessages.isEmpty {
                                    welcomeSection
                                }
                                
                                // Messages
                                ForEach(chatMessages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                // Loading indicator
                                if isGenerating {
                                    HStack(spacing: 10) {
                                        TypingIndicator()
                                        
                                        Text("AI is thinking...")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.vertical, 16)
                        }
                        .onChange(of: chatMessages.count) { _, _ in
                            if let lastMessage = chatMessages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Suggestions (show only when empty)
                    if chatMessages.isEmpty && !isGenerating {
                        suggestionsSection
                    }
                    
                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("AI Financial Advisor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        chatMessages.removeAll()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(chatMessages.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Welcome Section
    
    private var welcomeSection: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse.byLayer, options: .repeating)
            }
            
            // Title with slide animation
            VStack(spacing: 8) {
                Text("AI Financial Advisor")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Colors.text)
                
                Text("Ask me anything about your finances")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.subtext)
                    .multilineTextAlignment(.center)
            }
            
            // Features with stagger animation
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Spending analysis")
                FeatureRow(icon: "lightbulb.fill", text: "Money-saving tips")
                FeatureRow(icon: "target", text: "Budget recommendations")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DS.Colors.surface2)
            )
        }
        .padding()
    }
    
    // MARK: - Suggestions Section
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested questions:")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.subtext)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(suggestions.enumerated()), id: \.element) { index, suggestion in
                        Button {
                            sendMessage(suggestion)
                            Haptics.light()
                        } label: {
                            Text(suggestion)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(DS.Colors.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(DS.Colors.surface2)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                        }
                        .buttonStyle(SuggestionButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            // Text field with smooth focus animation
            TextField("Ask about your finances...", text: $userInput, axis: .vertical)
                .textFieldStyle(.plain)
                .font(DS.Typography.body)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(DS.Colors.surface2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    isInputFocused ?
                                    LinearGradient(
                                        colors: [.purple.opacity(0.5), .blue.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [.clear, .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .focused($isInputFocused)
                .lineLimit(1...4)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isInputFocused)
            
            // Send button with pulse animation
            Button {
                sendMessage(userInput)
                Haptics.medium()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: userInput.isEmpty ? [.gray.opacity(0.3), .gray.opacity(0.3)] : [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: userInput.isEmpty)
                }
                .scaleEffect(userInput.isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userInput.isEmpty)
            }
            .disabled(userInput.isEmpty || isGenerating)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            DS.Colors.bg
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
        )
    }
    
    // MARK: - Send Message
    
    private func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(text: trimmed, isFromUser: true)
        chatMessages.append(userMessage)
        
        // Clear input
        userInput = ""
        isInputFocused = false
        
        // Generate AI response
        Task {
            isGenerating = true
            
            do {
                // Build context-aware prompt
                let prompt = buildChatPrompt(userQuestion: trimmed)
                
                // Call Gemini API directly with the question
                let response = try await aiManager.generateChatResponse(prompt: prompt)
                
                await MainActor.run {
                    let aiMessage = ChatMessage(text: response, isFromUser: false)
                    chatMessages.append(aiMessage)
                    isGenerating = false
                    Haptics.success()
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        text: "Sorry, I couldn't process that. Please try again.",
                        isFromUser: false
                    )
                    chatMessages.append(errorMessage)
                    isGenerating = false
                    Haptics.error()
                }
            }
        }
    }
    
    // Build context-aware prompt for chat
    private func buildChatPrompt(userQuestion: String) -> String {
        let budget = Double(store.budgetTotal) / 100.0
        let spent = Double(store.spent(for: store.selectedMonth)) / 100.0
        let income = Double(store.income(for: store.selectedMonth)) / 100.0
        
        // Get spending by category
        let calendar = Calendar.current
        let monthTransactions = store.transactions.filter {
            calendar.isDate($0.date, equalTo: store.selectedMonth, toGranularity: .month) && $0.type == .expense
        }
        
        // Category breakdown
        var categoryBreakdown: [(String, Double)] = []
        for category in store.allCategories {
            let total = monthTransactions
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.amount }
            if total > 0 {
                categoryBreakdown.append((category.title, Double(total) / 100.0))
            }
        }
        categoryBreakdown.sort { $0.1 > $1.1 }
        
        var categoriesText = ""
        for (name, amount) in categoryBreakdown {
            categoriesText += "\(name): €\(String(format: "%.0f", amount))\n"
        }
        
        // Recent big expenses (top 5)
        let bigExpenses = monthTransactions
            .sorted { $0.amount > $1.amount }
            .prefix(5)
        
        var bigExpensesText = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        for tx in bigExpenses {
            let amt = Double(tx.amount) / 100.0
            let date = dateFormatter.string(from: tx.date)
            let note = tx.note.isEmpty ? "" : " - \(tx.note)"
            bigExpensesText += "\(date): €\(String(format: "%.0f", amt)) (\(tx.category.title))\(note)\n"
        }
        
        // Conversation history (last 4 messages only)
        var conversationHistory = ""
        let recentMessages = chatMessages.suffix(4)
        for msg in recentMessages {
            let prefix = msg.isFromUser ? "Q" : "A"
            conversationHistory += "\(prefix): \(msg.text)\n"
        }
        
        let monthName = dateFormatter.monthSymbols[calendar.component(.month, from: store.selectedMonth) - 1]
        
        return """
        Financial advisor chatbot. Give SHORT, DATA-FOCUSED answers.
        
        MONTH: \(monthName)
        Budget: €\(String(format: "%.0f", budget))
        Income: €\(String(format: "%.0f", income))
        Spent: €\(String(format: "%.0f", spent))
        Balance: €\(String(format: "%.0f", budget + income - spent))
        
        SPENDING BY CATEGORY:
        \(categoriesText)
        
        BIGGEST EXPENSES:
        \(bigExpensesText)
        
        CHAT HISTORY:
        \(conversationHistory.isEmpty ? "First message" : conversationHistory)
        
        USER: \(userQuestion)
        
        RULES:
        - Keep answers SHORT (1-2 sentences max)
        - Use ACTUAL DATA from above (numbers, dates, categories)
        - Be DIRECT and to the point
        - If asked "what was my biggest X" → give the EXACT transaction with date and amount
        - If asked to summarize → list top 3 categories with amounts
        - If previous answer was long, and they ask for summary → make it ONE sentence
        - Reference chat history if they're asking follow-up questions
        - No fluff, no "Hey there!", just facts
        
        Answer BRIEFLY with real data:
        """
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp = Date()
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    @State private var appeared = false
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(DS.Typography.body)
                    .foregroundStyle(message.isFromUser ? .white : DS.Colors.text)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                message.isFromUser
                                ? LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [DS.Colors.surface2, DS.Colors.surface2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .shadow(
                                color: message.isFromUser ?
                                    Color.purple.opacity(appeared ? 0.2 : 0) :
                                    Color.clear,
                                radius: 10,
                                x: 0,
                                y: 4
                            )
                    )
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)
                
                Text(timeAgo(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Colors.subtext)
                    .opacity(appeared ? 0.6 : 0)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.text)
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animateDot1 = false
    @State private var animateDot2 = false
    @State private var animateDot3 = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(DS.Colors.subtext)
                .frame(width: 8, height: 8)
                .scaleEffect(animateDot1 ? 1.2 : 0.8)
                .animation(
                    .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0.0),
                    value: animateDot1
                )
            
            Circle()
                .fill(DS.Colors.subtext)
                .frame(width: 8, height: 8)
                .scaleEffect(animateDot2 ? 1.2 : 0.8)
                .animation(
                    .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0.2),
                    value: animateDot2
                )
            
            Circle()
                .fill(DS.Colors.subtext)
                .frame(width: 8, height: 8)
                .scaleEffect(animateDot3 ? 1.2 : 0.8)
                .animation(
                    .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(0.4),
                    value: animateDot3
                )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DS.Colors.surface2)
        )
        .onAppear {
            animateDot1 = true
            animateDot2 = true
            animateDot3 = true
        }
    }
}

// MARK: - Suggestion Button Style

struct SuggestionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
