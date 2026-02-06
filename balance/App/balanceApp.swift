import SwiftUI
import FirebaseCore

@main
struct BalanceApp: App {
    @StateObject private var authManager = AuthManager()
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    
    init() {
        // Configure Firebase FIRST - before any Firebase calls
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.locale, .init(identifier: appLanguage))
                .environmentObject(authManager)
        }
    }
}
