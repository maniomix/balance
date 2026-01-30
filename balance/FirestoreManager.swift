import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class FirestoreManager: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    // MARK: - User Document Path
    
    private func userDocumentRef() -> DocumentReference? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(userId)
    }
    
    // MARK: - Save Store to Firestore
    
    func saveStore(_ store: Store) async throws {
        guard let userDoc = userDocumentRef() else {
            throw FirestoreError.notAuthenticated
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            print("💾 Saving store to Firestore...")
            print("  Transactions: \(store.transactions.count)")
            print("  Deleted IDs: \(store.deletedTransactionIds.count)")
            
            // تبدیل Store به dictionary
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(store)
            
            let sizeInKB = Double(data.count) / 1024.0
            let sizeInMB = sizeInKB / 1024.0
            print("  📊 Data size: \(String(format: "%.2f", sizeInKB)) KB (\(String(format: "%.2f", sizeInMB)) MB)")
            
            // Firestore limit is 1MB per document
            if data.count > 900_000 { // 900KB safety margin
                throw FirestoreError.documentTooLarge
            }
            
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            print("  Dictionary keys: \(dict.keys.joined(separator: ", "))")
            
            // ذخیره در Firestore
            try await userDoc.setData([
                "store": dict,
                "lastUpdated": FieldValue.serverTimestamp()
            ], merge: true)
            
            print("✅ Store saved successfully")
            
            lastSyncDate = Date()
            isSyncing = false
        } catch let error as NSError {
            print("❌ Save error: \(error)")
            print("  Domain: \(error.domain)")
            print("  Code: \(error.code)")
            print("  Description: \(error.localizedDescription)")
            if let userInfo = error.userInfo as? [String: Any] {
                print("  UserInfo: \(userInfo)")
            }
            
            isSyncing = false
            
            // Better error messages
            if error.code == 7 {
                syncError = "Permission denied. Check Firestore Rules."
            } else if error.code == 3 {
                syncError = "Document too large. Too many transactions."
            } else {
                syncError = error.localizedDescription
            }
            
            throw error
        }
    }
    
    // MARK: - Load Store from Firestore
    
    func loadStore() async throws -> Store? {
        guard let userDoc = userDocumentRef() else {
            throw FirestoreError.notAuthenticated
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            let snapshot = try await userDoc.getDocument()
            
            guard snapshot.exists,
                  let storeData = snapshot.data()?["store"] as? [String: Any] else {
                isSyncing = false
                return nil
            }
            
            // تبدیل dictionary به Store
            let jsonData = try JSONSerialization.data(withJSONObject: storeData)
            let decoder = JSONDecoder()
            let store = try decoder.decode(Store.self, from: jsonData)
            
            lastSyncDate = Date()
            isSyncing = false
            
            return store
        } catch {
            isSyncing = false
            syncError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sync (Smart Merge)
    
    func syncStore(_ localStore: Store) async throws -> Store {
        guard let userDoc = userDocumentRef() else {
            throw FirestoreError.notAuthenticated
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            let snapshot = try await userDoc.getDocument()
            
            if !snapshot.exists {
                // هیچ دیتایی در cloud نیست → آپلود local
                print("☁️ No cloud data, uploading local")
                try await saveStore(localStore)
                lastSyncDate = Date()
                isSyncing = false
                return localStore
            }
            
            guard let cloudStoreData = snapshot.data()?["store"] as? [String: Any] else {
                // دیتای cloud خراب → استفاده از local
                print("⚠️ Invalid cloud data, uploading local")
                try await saveStore(localStore)
                lastSyncDate = Date()
                isSyncing = false
                return localStore
            }
            
            // تبدیل cloud data به Store
            let jsonData = try JSONSerialization.data(withJSONObject: cloudStoreData)
            let decoder = JSONDecoder()
            let cloudStore = try decoder.decode(Store.self, from: jsonData)
            
            // Check if local has newer changes
            let hasLocalChanges = hasNewerChanges(local: localStore, cloud: cloudStore)
            
            if hasLocalChanges {
                print("✅ Local has newer changes, merging and uploading")
                // Local دارای تغییرات جدیدتر → merge و آپلود
                let mergedStore = mergeStores(local: localStore, cloud: cloudStore)
                try await saveStore(mergedStore)
                
                lastSyncDate = Date()
                isSyncing = false
                return mergedStore
            } else {
                print("⬇️ Cloud is up-to-date, downloading only")
                // Cloud جدیدتر یا برابر → فقط download
                lastSyncDate = Date()
                isSyncing = false
                return cloudStore
            }
        } catch {
            isSyncing = false
            syncError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Check for Local Changes
    
    private func hasNewerChanges(local: Store, cloud: Store) -> Bool {
        // Check for deleted transactions
        if !local.deletedTransactionIds.isEmpty {
            let localDeleted = Set(local.deletedTransactionIds)
            let cloudDeleted = Set(cloud.deletedTransactionIds)
            let hasNewDeletes = !localDeleted.isSubset(of: cloudDeleted)
            if hasNewDeletes {
                print("  → Local has new deletions")
                return true
            }
        }
        
        // Check transactions
        let localTxIds = Set(local.transactions.map { $0.id })
        let cloudTxIds = Set(cloud.transactions.map { $0.id })
        
        // آیا transaction جدیدی local داره که cloud نداره?
        if !localTxIds.isSubset(of: cloudTxIds) {
            print("  → Local has new transactions")
            return true
        }
        
        // آیا transaction مشترکی هست که local جدیدتره؟
        for tx in local.transactions {
            if let cloudTx = cloud.transactions.first(where: { $0.id == tx.id }) {
                if tx.lastModified > cloudTx.lastModified {
                    print("  → Local transaction \(tx.id) is newer: local=\(tx.lastModified) > cloud=\(cloudTx.lastModified)")
                    return true
                }
            }
        }
        
        // Check budgets
        for (month, budget) in local.budgetsByMonth {
            if let cloudBudget = cloud.budgetsByMonth[month] {
                if budget != cloudBudget {
                    print("  → Budget changed for \(month)")
                    return true
                }
            } else {
                print("  → New budget for \(month)")
                return true
            }
        }
        
        // Check custom categories
        if Set(local.customCategoryNames) != Set(cloud.customCategoryNames) {
            print("  → Custom categories changed")
            return true
        }
        
        return false
    }
    
    // MARK: - Merge Logic
    
    private func mergeStores(local: Store, cloud: Store) -> Store {
        var merged = local
        
        print("🔄 Merging stores:")
        print("  Local transactions: \(local.transactions.count)")
        print("  Cloud transactions: \(cloud.transactions.count)")
        print("  Deleted IDs: \(local.deletedTransactionIds.count)")
        
        // Merge deleted IDs from both (convert to Set for deduplication)
        let allDeletedIds = Set(local.deletedTransactionIds + cloud.deletedTransactionIds)
        merged.deletedTransactionIds = Array(allDeletedIds)
        
        // Merge transactions با timestamp-based conflict resolution
        var transactionDict: [UUID: Transaction] = [:]
        var conflicts = 0
        var localWins = 0
        var cloudWins = 0
        
        // ابتدا همه transactions رو collect کن (به جز deleted ones)
        for tx in cloud.transactions {
            if !allDeletedIds.contains(tx.id.uuidString) {
                transactionDict[tx.id] = tx
            } else {
                print("  🗑️ Skipping deleted cloud transaction: \(tx.id)")
            }
        }
        
        for tx in local.transactions {
            if allDeletedIds.contains(tx.id.uuidString) {
                print("  🗑️ Skipping deleted local transaction: \(tx.id)")
                continue
            }
            
            if let cloudTx = transactionDict[tx.id] {
                conflicts += 1
                // اگه هر دو وجود دارند، جدیدتر wins (based on lastModified)
                if tx.lastModified > cloudTx.lastModified {
                    print("  ✅ Local wins for \(tx.id): local=\(tx.lastModified) > cloud=\(cloudTx.lastModified)")
                    transactionDict[tx.id] = tx  // local جدیدتره
                    localWins += 1
                } else {
                    print("  ☁️ Cloud wins for \(tx.id): cloud=\(cloudTx.lastModified) >= local=\(tx.lastModified)")
                    cloudWins += 1
                }
            } else {
                // transaction فقط local داره
                transactionDict[tx.id] = tx
            }
        }
        
        print("  Conflicts: \(conflicts), Local wins: \(localWins), Cloud wins: \(cloudWins)")
        print("  Merged transactions: \(transactionDict.count)")
        
        merged.transactions = Array(transactionDict.values).sorted { $0.date > $1.date }
        
        // Merge budgets (local wins if both exist)
        for (month, budget) in cloud.budgetsByMonth {
            if merged.budgetsByMonth[month] == nil {
                merged.budgetsByMonth[month] = budget
            }
            // اگه هر دو دارن، local wins
        }
        
        // Merge category budgets
        for (month, cats) in cloud.categoryBudgetsByMonth {
            if merged.categoryBudgetsByMonth[month] == nil {
                merged.categoryBudgetsByMonth[month] = cats
            } else {
                // Merge categories for this month
                for (cat, budget) in cats {
                    if merged.categoryBudgetsByMonth[month]?[cat] == nil {
                        merged.categoryBudgetsByMonth[month]?[cat] = budget
                    }
                    // اگه هر دو دارن، local wins
                }
            }
        }
        
        // Merge custom categories
        let allCustomCategories = Set(local.customCategoryNames + cloud.customCategoryNames)
        merged.customCategoryNames = Array(allCustomCategories).sorted()
        
        return merged
    }
    
    // MARK: - Delete User Data
    
    func deleteUserData() async throws {
        guard let userDoc = userDocumentRef() else {
            throw FirestoreError.notAuthenticated
        }
        
        try await userDoc.delete()
    }
    
    // MARK: - Profile Management
    
    func saveProfile(displayName: String, profileImageData: Data?) async throws {
        guard let userDoc = userDocumentRef() else {
            throw FirestoreError.notAuthenticated
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            var profileData: [String: Any] = [
                "displayName": displayName,
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            // Convert image data to base64 if exists
            if let imageData = profileImageData {
                let base64String = imageData.base64EncodedString()
                profileData["profileImage"] = base64String
            }
            
            try await userDoc.setData([
                "profile": profileData
            ], merge: true)
            
            lastSyncDate = Date()
            isSyncing = false
        } catch {
            isSyncing = false
            syncError = error.localizedDescription
            throw error
        }
    }
    
    func loadProfile() async throws -> (displayName: String, profileImageData: Data?)? {
        guard let userDoc = userDocumentRef() else {
            throw FirestoreError.notAuthenticated
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            let snapshot = try await userDoc.getDocument()
            
            guard snapshot.exists,
                  let profileData = snapshot.data()?["profile"] as? [String: Any] else {
                isSyncing = false
                return nil
            }
            
            let displayName = profileData["displayName"] as? String ?? ""
            
            var imageData: Data? = nil
            if let base64String = profileData["profileImage"] as? String {
                imageData = Data(base64Encoded: base64String)
            }
            
            lastSyncDate = Date()
            isSyncing = false
            
            return (displayName, imageData)
        } catch {
            isSyncing = false
            syncError = error.localizedDescription
            throw error
        }
    }
}

// MARK: - Errors

enum FirestoreError: LocalizedError {
    case notAuthenticated
    case invalidData
    case documentTooLarge
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidData:
            return "Invalid data format"
        case .documentTooLarge:
            return "Document too large (>900KB). Please delete old transactions."
        }
    }
}
