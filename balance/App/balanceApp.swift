import SwiftUI
import FirebaseCore

@main
struct BalanceApp: App {
    @StateObject private var authManager = AuthManager()
    @AppStorage("app.theme") private var selectedTheme: String = "dark"
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            
            ContentView()
                .preferredColorScheme(selectedTheme == "dark" ? .dark : .light)
                .environmentObject(authManager)

        }
    }
}
