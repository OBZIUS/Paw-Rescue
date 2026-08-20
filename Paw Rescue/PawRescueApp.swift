import SwiftUI
import AuthenticationServices

@main
struct PawRescueApp: App {
    @StateObject private var appState   = AppState()
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authManager)
                // Whenever auth state changes, sync userName + navigate to map + load live data
                .onChange(of: authManager.isAuthenticated) { _, authenticated in
                    if authenticated {
                        if !authManager.currentUserName.isEmpty && authManager.currentUserName.lowercased() != "rescuer" {
                            appState.userName = authManager.currentUserName
                        }
                        appState.selectedTab = .map
                        appState.isSignedIn = true
                        appState.loadReports()
                        appState.loadFeedPosts()
                        appState.syncUserStats(userID: authManager.currentUserID)
                    } else {
                        appState.isSignedIn = false
                    }
                }
                // On cold launch if already signed in, load fresh data
                .onAppear {
                    if authManager.isAuthenticated && appState.isSignedIn {
                        if !authManager.currentUserName.isEmpty && authManager.currentUserName.lowercased() != "rescuer" {
                            appState.userName = authManager.currentUserName
                        }
                        appState.loadReports()
                        appState.loadFeedPosts()
                        appState.syncUserStats(userID: authManager.currentUserID)
                    }
                }
        }
    }
}

// MARK: - Root View
/// Switches between onboarding, sign-in, and main app based on persistent state.
struct RootView: View {
    @EnvironmentObject private var appState:    AppState
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !appState.isSignedIn || !authManager.isAuthenticated {
                SignInView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appState.isSignedIn)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}
