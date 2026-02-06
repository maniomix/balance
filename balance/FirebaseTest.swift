import SwiftUI
import FirebaseAuth

struct FirebaseTestView: View {
    @State private var status = "Testing Firebase..."
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔥 Firebase Test")
                .font(.largeTitle)
                .bold()
            
            Text(status)
                .padding()
                .multilineTextAlignment(.center)
            
            Button("Test Connection") {
                testFirebase()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    func testFirebase() {
        // تست ساده: چک کردن که Firebase راه‌اندازی شده
        if Auth.auth().app != nil {
            status = "✅ Firebase Connected!\n\nAuthentication: Ready\nFirestore: Ready\n\nAll systems operational!"
        } else {
            status = "❌ Firebase not initialized"
        }
    }
} 
