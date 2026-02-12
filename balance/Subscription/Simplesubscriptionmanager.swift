import Foundation
import FirebaseFirestore
import Combine

// MARK: - Simple Subscription Manager (Firebase-based)
@MainActor
class SimpleSubscriptionManager: ObservableObject {
    static let shared = SimpleSubscriptionManager()
    
    // Published states
    @Published var isPro = false
    @Published var subscriptionType: SubscriptionType = .free
    @Published var expirationDate: Date?
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var userId: String?
    
    enum SubscriptionType: String, Codable {
        case free = "free"
        case monthly = "monthly"
        case yearly = "yearly"
    }
    
    init() {
        // Load subscription status on init
    }
    
    // MARK: - Load Subscription Status
    func loadSubscriptionStatus(userId: String) async {
        self.userId = userId
        isLoading = true
        
        do {
            let docRef = db.collection("subscriptions").document(userId)
            let document = try await docRef.getDocument()
            
            if document.exists,
               let data = document.data(),
               let typeString = data["type"] as? String,
               let type = SubscriptionType(rawValue: typeString) {
                
                subscriptionType = type
                
                // چک کردن تاریخ انقضا
                if let timestamp = data["expirationDate"] as? Timestamp {
                    let expiration = timestamp.dateValue()
                    expirationDate = expiration
                    
                    // اگر expire شده، برگردون به free
                    if expiration < Date() {
                        subscriptionType = .free
                        isPro = false
                    } else {
                        isPro = (type != .free)
                    }
                } else {
                    isPro = (type != .free)
                }
            } else {
                // اگر document وجود نداره، free هست
                subscriptionType = .free
                isPro = false
            }
            
            isLoading = false
        } catch {
            print("Error loading subscription: \(error)")
            subscriptionType = .free
            isPro = false
            isLoading = false
        }
    }
    
    // MARK: - Activate Subscription (Manual)
    func activateSubscription(userId: String, type: SubscriptionType) async {
        self.userId = userId
        isLoading = true
        
        // محاسبه تاریخ انقضا
        let calendar = Calendar.current
        let expiration: Date
        
        switch type {
        case .monthly:
            expiration = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        case .yearly:
            expiration = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        case .free:
            expiration = Date()
        }
        
        do {
            let docRef = db.collection("subscriptions").document(userId)
            try await docRef.setData([
                "type": type.rawValue,
                "expirationDate": Timestamp(date: expiration),
                "activatedAt": Timestamp(date: Date()),
                "userId": userId
            ])
            
            subscriptionType = type
            expirationDate = expiration
            isPro = (type != .free)
            isLoading = false
        } catch {
            print("Error activating subscription: \(error)")
            isLoading = false
        }
    }
    
    // MARK: - Cancel Subscription
    func cancelSubscription(userId: String) async {
        isLoading = true
        
        do {
            let docRef = db.collection("subscriptions").document(userId)
            try await docRef.updateData([
                "type": SubscriptionType.free.rawValue,
                "expirationDate": Timestamp(date: Date())
            ])
            
            subscriptionType = .free
            expirationDate = Date()
            isPro = false
            isLoading = false
        } catch {
            print("Error canceling subscription: \(error)")
            isLoading = false
        }
    }
    
    // MARK: - Check if subscription is valid
    func isSubscriptionValid() -> Bool {
        guard isPro else { return false }
        
        if let expiration = expirationDate {
            return expiration > Date()
        }
        
        return false
    }
    
    // MARK: - Get remaining days
    func remainingDays() -> Int {
        guard let expiration = expirationDate else { return 0 }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiration)
        return max(0, components.day ?? 0)
    }
}
