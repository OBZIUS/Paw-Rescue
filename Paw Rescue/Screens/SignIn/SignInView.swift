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
                Text("Get started")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppColors.black)
                    .padding(.top, 60)
                
                Spacer()
                
                // App Logo
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
                .scaleEffect(isBouncing ? 1.54 : 1.56)
                .offset(y: isBouncing ? -20 : 6)
                
                Spacer()
                    .frame(height: 48)
                
                Text("A quick sign-in keeps our rescue community safe and trusted, so we can focus on helping dogs in need.")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(Color(hex: "6C707A"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .padding(.top, 60)
                
                // Error message
                if let errMsg = authManager.signInErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(errMsg)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                // Native SwiftUI Apple Sign In Button
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        authManager.handleAuthorization(authorization)
                        appState.selectedTab = .map
                        appState.isSignedIn = true
                        appState.loadReports()
                        appState.loadFeedPosts()

                        // Apple only sends the real name on this device's very first
                        // authorization — grab it into AppState right away so Profile
                        // shows it instead of falling back to "Rescuer".
                        if !authManager.currentUserName.isEmpty &&
                            authManager.currentUserName.lowercased() != "rescuer" {
                            appState.userName = authManager.currentUserName
                        }

                        // For returning users Apple won't resend the name, so resolve
                        // it from CloudKit / iCloud identity and sync it in once found.
                        let uid = authManager.currentUserID
                        Task {
                            await authManager.resolveAndPersistRealUserName(forUserID: uid)
                            await MainActor.run {
                                if !authManager.currentUserName.isEmpty &&
                                    authManager.currentUserName.lowercased() != "rescuer" {
                                    appState.userName = authManager.currentUserName
                                }
                            }
                        }
                    case .failure(let error):
                        authManager.handleAuthorizationError(error)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(Capsule())
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
}

#Preview {
    SignInView()
        .environmentObject(AppState())
        .environmentObject(AuthManager.shared)
}
