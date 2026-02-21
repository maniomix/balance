import SwiftUI
import Supabase

struct SyncStatusView: View {
    @EnvironmentObject private var supabase: SupabaseManager
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        HStack(spacing: 8) {
            // Sync Icon
            if supabase.isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(Color(uiColor: .secondaryLabel))
            } else {
                Image(systemName: syncIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(syncColor)
            }
            
            // Status Text
            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(uiColor: .label))
                
                if let lastSync = supabase.lastSyncTime {
                    Text(timeAgo(from: lastSync))
                        .font(.system(size: 11))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            }
            
            Spacer()
            
            // User Info
            if let user = authManager.currentUser {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                    
                    Text(userDisplayName(user))
                        .font(.system(size: 12))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        if supabase.isSyncing {
            return "Syncing..."
        } else if let error = supabase.syncError {
            return "Sync failed"
        } else if supabase.lastSyncTime != nil {
            return "Synced"
        } else {
            return "Not synced"
        }
    }
    
    private var syncIcon: String {
        if let error = supabase.syncError {
            return "exclamationmark.triangle.fill"
        } else if supabase.lastSyncTime != nil {
            return "checkmark.icloud.fill"
        } else {
            return "icloud.slash.fill"
        }
    }
    
    private var syncColor: Color {
        if let error = supabase.syncError {
            return .red
        } else if supabase.lastSyncTime != nil {
            return .green
        } else {
            return Color(uiColor: .secondaryLabel)
        }
    }
    
    // MARK: - Helper Functions
    
    private func userDisplayName(_ user: User) -> String {
        if let email = user.email {
            return email.components(separatedBy: "@").first ?? email
        }
        return "User"
    }
    
    private func timeAgo(from date: Date) -> String {
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

#Preview {
    SyncStatusView()
        .environmentObject(SupabaseManager.shared)
        .environmentObject(AuthManager.shared)
        .padding()
}
