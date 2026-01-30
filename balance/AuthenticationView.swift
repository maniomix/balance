import SwiftUI

struct AuthenticationView: View {
    @State private var showSignUp = false
    
    var body: some View {
        Group {
            if showSignUp {
                SignUpView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSignUp = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            } else {
                LoginView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSignUp = true
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .trailing)
                ))
            }
        }
    }
}
