import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject private var appState:    AppState
    @EnvironmentObject private var authManager: AuthManager
    @State private var isBouncing = false
    
    var body: some View {
        ZStack {
            AppColors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Title: "Get started"
                Text("Get started")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppColors.black)
                    .padding(.top, 60)
                
                Spacer()
                
                // Center Ball Bouncing & Growing App Logo
                Group {
                    if UIImage(named: "AppLogo") != nil {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 220, weight: .medium))
                            .foregroundColor(AppColors.primaryBlue)
                    }
                }
                // Ball bounce motion with growth
                .scaleEffect(isBouncing ? 1.54 : 1.56)
                .offset(y: isBouncing ? -20 : 6)
                
                Spacer()
                    .frame(height: 48)
                
                // Supporting text
                Text("A quick sign-in keeps our rescue community safe and trusted, so we can focus on helping dogs in need.")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(Color(hex: "6C707A"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .padding(.top, 60)
                
                Spacer()
                
                // MARK: - Real Sign In with Apple Button
                // ASAuthorizationAppleIDButton wrapped in SwiftUI.
                // Requires "Sign In with Apple" capability in Xcode → Signing & Capabilities.
                AppleSignInButton {
                    authManager.performSignIn(anchor: currentWindow())
                }
                .frame(height: 52)
                .padding(.horizontal, 48)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.4)
                .repeatForever(autoreverses: true)
            ) {
                isBouncing = true
            }
        }
    }
    
    // MARK: - Helpers
    private func currentWindow() -> UIWindow {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Apple Sign In Button Wrapper
/// Wraps ASAuthorizationAppleIDButton so it renders correctly in SwiftUI.
struct AppleSignInButton: UIViewRepresentable {
    var action: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(
            authorizationButtonType:  .signIn,
            authorizationButtonStyle: .black
        )
        button.cornerRadius = 26
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(action: action) }
    
    final class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}

#Preview {
    SignInView()
        .environmentObject(AppState())
        .environmentObject(AuthManager.shared)
}
