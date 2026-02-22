// ==========================================
// SyncBanner - Tappable Sync Status
// ==========================================

import SwiftUI

struct SyncBanner: View {
    @Binding var lastSyncTime: Date?
    let onTap: () async -> Void
    @State private var isSyncing = false
    
    var body: some View {
        Button {
            guard !isSyncing else { return }
            Task {
                isSyncing = true
                await onTap()
                isSyncing = false
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    if isSyncing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    } else {
                        Image(systemName: "checkmark.icloud.fill")
                            .foregroundColor(.green)
                    }
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Synced")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let lastSync = lastSyncTime {
                        Text(timeAgo(lastSync))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Hint
                Text("Tap to sync")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))h ago"
        } else {
            return "\(Int(seconds / 86400))d ago"
        }
    }
}
