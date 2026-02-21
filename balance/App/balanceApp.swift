import SwiftUI

@main
struct balanceApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var authManager = AuthManager.shared
    
    init() {
        // Setup app on launch
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(supabaseManager)
                .environmentObject(authManager)
        }
    }
}
