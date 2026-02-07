import SwiftUI
import FirebaseAuth

struct SyncStatusView: View {
    @ObservedObject var firestoreManager: FirestoreManager
    @Binding var store: Store
    @State private var isManualSyncing = false
    @State private var syncButtonPressed = false
    @State private var showErrorAlert = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Status Indicator
            statusIndicator
                .frame(minWidth: 100) // Minimum width to prevent jumping
                .frame(height: 32)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: firestoreManager.isSyncing)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isManualSyncing)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: firestoreManager.lastSyncDate)
            
            // Manual Sync Button
            if !firestoreManager.isSyncing && !isManualSyncing {
                syncButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: firestoreManager.isSyncing)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isManualSyncing)
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            if firestoreManager.isSyncing || isManualSyncing {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.white)
                Text("Syncing...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            } else if let error = firestoreManager.syncError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 14))
                    .transition(.scale.combined(with: .opacity))
                Button {
                    showErrorAlert = true
                } label: {
                    Text("Sync failed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
                .alert("Sync Error", isPresented: $showErrorAlert) {
                    Button("OK") {
                        showErrorAlert = false
                    }
                } message: {
                    Text(error)
                }
            } else if let _ = firestoreManager.lastSyncDate {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 14))
                    .transition(.scale.combined(with: .opacity))
                Text(timeAgo(firestoreManager.lastSyncDate!))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private var syncButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                syncButtonPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    syncButtonPressed = false
                }
            }
            
            manualSync()
        } label: {
            Text("Sync")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .buttonStyle(.plain)
        .frame(width: 55, height: 32) // Fixed size
        .background(
            Capsule()
                .fill(Color.white.opacity(syncButtonPressed ? 0.25 : 0.12))
        )
        .scaleEffect(syncButtonPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: syncButtonPressed)
    }
    
    private func manualSync() {
        guard !isManualSyncing else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isManualSyncing = true
        Haptics.light()
        
        Task {
            do {
                let syncedStore = try await firestoreManager.syncStore(store, userId: userId)
                await MainActor.run {
                    store = syncedStore
                    store.save(userId: userId)
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isManualSyncing = false
                    }
                    Haptics.success()
                }
            } catch {
                print("Manual sync error: \(error)")
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isManualSyncing = false
                    }
                    Haptics.medium()
                }
            }
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}
