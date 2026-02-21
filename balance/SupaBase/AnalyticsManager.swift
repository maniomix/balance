import Foundation
import SwiftUI
import Combine

// MARK: - Analytics Manager
@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var sessionStart: Date?
    @Published var sessionId: UUID?
    
    private var supabase: SupabaseManager {
        SupabaseManager.shared
    }
    
    private init() {}
    
    // MARK: - 📊 1. User Metrics
    
    /// Track user signup
    func trackSignup(userId: String, source: String = "organic") {
        Task {
            await logEvent(
                name: "user_signup",
                properties: [
                    "user_id": userId,
                    "source": source,
                    "platform": "ios"
                ]
            )
        }
    }
    
    /// Track daily active user
    func trackDailyActive(userId: String) {
        Task {
            await logEvent(
                name: "daily_active",
                properties: ["user_id": userId]
            )
        }
    }
    
    // MARK: - 🔁 2. Retention Metrics
    
    /// Track app open (for retention calculation)
    func trackAppOpen(userId: String) {
        Task {
            await logEvent(
                name: "app_open",
                properties: [
                    "user_id": userId,
                    "days_since_signup": calculateDaysSinceSignup(userId: userId)
                ]
            )
        }
    }
    
    // MARK: - ⏱ 3. Engagement Metrics
    
    /// Start session tracking
    func startSession(userId: String) {
        sessionId = UUID()
        sessionStart = Date()
        
        Task {
            await logEvent(
                name: "session_start",
                properties: [
                    "user_id": userId,
                    "session_id": sessionId!.uuidString
                ]
            )
        }
    }
    
    /// End session tracking
    func endSession(userId: String) {
        guard let start = sessionStart, let sid = sessionId else { return }
        
        let duration = Int(Date().timeIntervalSince(start))
        
        Task {
            await logEvent(
                name: "session_end",
                properties: [
                    "user_id": userId,
                    "session_id": sid.uuidString,
                    "duration_seconds": String(duration)
                ]
            )
        }
        
        sessionStart = nil
        sessionId = nil
    }
    
    /// Track feature usage
    func trackFeatureUsage(userId: String, feature: String, duration: TimeInterval? = nil) {
        var props: [String: String] = [
            "user_id": userId,
            "feature": feature
        ]
        
        if let duration = duration {
            props["duration_seconds"] = String(Int(duration))
        }
        
        Task {
            await logEvent(
                name: "feature_usage",
                properties: props
            )
        }
    }
    
    /// Track user action
    func trackAction(userId: String, action: String, metadata: [String: String] = [:]) {
        var props = metadata
        props["user_id"] = userId
        props["action"] = action
        
        Task {
            await logEvent(
                name: "user_action",
                properties: props
            )
        }
    }
    
    // MARK: - 💰 4. Monetization Signals
    
    /// Track pro button click
    func trackProButtonClick(userId: String, location: String) {
        Task {
            await logEvent(
                name: "pro_button_click",
                properties: [
                    "user_id": userId,
                    "location": location
                ]
            )
        }
    }
    
    /// Track upgrade page view
    func trackUpgradePageView(userId: String) {
        Task {
            await logEvent(
                name: "upgrade_page_view",
                properties: ["user_id": userId]
            )
        }
    }
    
    /// Track trial start
    func trackTrialStart(userId: String, plan: String) {
        Task {
            await logEvent(
                name: "trial_start",
                properties: [
                    "user_id": userId,
                    "plan": plan
                ]
            )
        }
    }
    
    /// Track conversion to paid
    func trackConversion(userId: String, plan: String, price: Double) {
        Task {
            await logEvent(
                name: "conversion",
                properties: [
                    "user_id": userId,
                    "plan": plan,
                    "price": String(price)
                ]
            )
        }
    }
    
    // MARK: - 📈 5. Growth & Acquisition
    
    /// Track referral
    func trackReferral(userId: String, referredUserId: String) {
        Task {
            await logEvent(
                name: "referral",
                properties: [
                    "user_id": userId,
                    "referred_user_id": referredUserId
                ]
            )
        }
    }
    
    /// Track social share
    func trackShare(userId: String, platform: String) {
        Task {
            await logEvent(
                name: "share",
                properties: [
                    "user_id": userId,
                    "platform": platform
                ]
            )
        }
    }
    
    // MARK: - 🧠 6. Product Health
    
    /// Track error/crash
    func trackError(userId: String?, error: Error, context: String) {
        var props: [String: String] = [
            "error": error.localizedDescription,
            "context": context
        ]
        
        if let userId = userId {
            props["user_id"] = userId
        }
        
        Task {
            await logEvent(
                name: "error",
                properties: props
            )
        }
    }
    
    /// Track performance metric
    func trackPerformance(metric: String, value: Double) {
        Task {
            await logEvent(
                name: "performance",
                properties: [
                    "metric": metric,
                    "value": String(value)
                ]
            )
        }
    }
    
    // MARK: - 💎 7. Advanced Metrics
    
    /// Track funnel step
    func trackFunnel(userId: String, step: String, completed: Bool) {
        Task {
            await logEvent(
                name: "funnel_\(step)",
                properties: [
                    "user_id": userId,
                    "completed": completed ? "true" : "false"
                ]
            )
        }
    }
    
    /// Track transaction (for calculating ARPU/LTV)
    func trackTransaction(userId: String, amount: Double, type: String) {
        Task {
            await logEvent(
                name: "transaction",
                properties: [
                    "user_id": userId,
                    "amount": String(amount),
                    "type": type
                ]
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func logEvent(name: String, properties: [String: String]) async {
        do {
            try await supabase.trackEvent(name: name, properties: properties)
        } catch {
            print("❌ Analytics error: \(error)")
        }
    }
    
    private func calculateDaysSinceSignup(userId: String) -> String {
        // TODO: Implement based on user's signup date
        return "0"
    }
}

// MARK: - Common Event Names
extension AnalyticsManager {
    enum Event {
        // User lifecycle
        static let signup = "user_signup"
        static let login = "user_login"
        static let logout = "user_logout"
        
        // Engagement
        static let sessionStart = "session_start"
        static let sessionEnd = "session_end"
        static let featureUsage = "feature_usage"
        
        // Transactions
        static let transactionAdded = "transaction_added"
        static let transactionEdited = "transaction_edited"
        static let transactionDeleted = "transaction_deleted"
        
        // Budgets
        static let budgetSet = "budget_set"
        static let budgetExceeded = "budget_exceeded"
        
        // Monetization
        static let proButtonClick = "pro_button_click"
        static let upgradeView = "upgrade_page_view"
        static let trialStart = "trial_start"
        static let conversion = "conversion"
        
        // Growth
        static let referral = "referral"
        static let share = "share"
        
        // Product
        static let error = "error"
        static let performance = "performance"
    }
    
    enum Feature {
        static let dashboard = "dashboard"
        static let transactions = "transactions"
        static let budget = "budget"
        static let insights = "insights"
        static let settings = "settings"
        static let exportData = "export"
        static let importData = "import"
    }
}

// MARK: - View Modifier for automatic tracking
struct TrackView: ViewModifier {
    let screen: String
    let userId: String?
    
    @State private var appeared = Date()
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                appeared = Date()
                if let userId = userId {
                    AnalyticsManager.shared.trackFeatureUsage(
                        userId: userId,
                        feature: screen
                    )
                }
            }
            .onDisappear {
                if let userId = userId {
                    let duration = Date().timeIntervalSince(appeared)
                    AnalyticsManager.shared.trackFeatureUsage(
                        userId: userId,
                        feature: screen,
                        duration: duration
                    )
                }
            }
    }
}

extension View {
    func trackScreen(_ screen: String, userId: String?) -> some View {
        modifier(TrackView(screen: screen, userId: userId))
    }
}
