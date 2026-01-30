import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FirestoreTestView: View {
    @State private var testResult = "Not tested yet"
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DS.Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Firestore Connection Test")
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)
                            
                            Divider().overlay(DS.Colors.grid)
                            
                            Text(testResult)
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.subtext)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    Button {
                        testFirestoreConnection()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "network")
                                Text("Test Connection")
                            }
                        }
                    }
                    .buttonStyle(DS.PrimaryButton())
                    .disabled(isLoading)
                    
                    Button {
                        testSimpleWrite()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "square.and.pencil")
                                Text("Test Write")
                            }
                        }
                    }
                    .buttonStyle(DS.ColoredButton())
                    .disabled(isLoading)
                    
                    Button {
                        checkFirestoreRules()
                    } label: {
                        HStack {
                            Image(systemName: "shield.checkered")
                            Text("Check Rules")
                        }
                    }
                    .buttonStyle(DS.ColoredButton())
                }
                .padding(16)
            }
            .background(DS.Colors.bg.ignoresSafeArea())
            .navigationTitle("Firestore Test")
        }
    }
    
    private func testFirestoreConnection() {
        isLoading = true
        testResult = "Testing connection..."
        
        Task {
            do {
                guard let userId = Auth.auth().currentUser?.uid else {
                    await MainActor.run {
                        testResult = "❌ Not authenticated. Please login first."
                        isLoading = false
                    }
                    return
                }
                
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(userId)
                
                let snapshot = try await docRef.getDocument()
                
                await MainActor.run {
                    if snapshot.exists {
                        testResult = "✅ Connected! Document exists.\nUser ID: \(userId)"
                    } else {
                        testResult = "⚠️ Connected, but no document found.\nUser ID: \(userId)\n\nThis is normal for new users."
                    }
                    isLoading = false
                }
            } catch let error as NSError {
                await MainActor.run {
                    testResult = """
                    ❌ Connection failed:
                    Error: \(error.localizedDescription)
                    Domain: \(error.domain)
                    Code: \(error.code)
                    
                    If code is 7, check Firestore Rules in Firebase Console.
                    """
                    isLoading = false
                }
            }
        }
    }
    
    private func testSimpleWrite() {
        isLoading = true
        testResult = "Testing write..."
        
        Task {
            do {
                guard let userId = Auth.auth().currentUser?.uid else {
                    await MainActor.run {
                        testResult = "❌ Not authenticated."
                        isLoading = false
                    }
                    return
                }
                
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(userId)
                
                // Simple test data
                try await docRef.setData([
                    "test": "Hello from Balance app",
                    "timestamp": FieldValue.serverTimestamp()
                ], merge: true)
                
                await MainActor.run {
                    testResult = "✅ Write successful!\n\nFirestore is working correctly."
                    isLoading = false
                }
            } catch let error as NSError {
                await MainActor.run {
                    testResult = """
                    ❌ Write failed:
                    Error: \(error.localizedDescription)
                    Code: \(error.code)
                    
                    Common causes:
                    • Firestore Rules deny write
                    • Network connection issue
                    • Invalid data format
                    """
                    isLoading = false
                }
            }
        }
    }
    
    private func checkFirestoreRules() {
        testResult = """
        📋 Required Firestore Rules:
        
        Go to Firebase Console:
        1. Firestore Database → Rules
        2. Copy this:
        
        rules_version = '2';
        service cloud.firestore {
          match /databases/{database}/documents {
            match /users/{userId} {
              allow read, write: if request.auth != null && request.auth.uid == userId;
            }
          }
        }
        
        3. Click "Publish"
        
        Current user: \(Auth.auth().currentUser?.uid ?? "Not logged in")
        """
    }
}
