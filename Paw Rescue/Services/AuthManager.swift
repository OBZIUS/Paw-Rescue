import AuthenticationServices
import Security
import SwiftUI

/// Manages Sign In with Apple authentication.
/// Persists credentials in Keychain, resolves user names from Apple / iCloud / CloudKit,
/// and validates authentication state.
final class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUserName: String = ""
    @Published var currentUserEmail: String = ""
    @Published var currentUserID: String = ""
    @Published var signInErrorMessage: String? = nil
    @Published var isSigningIn: Bool = false
    
    // Keychain keys
    private let userIDKey    = "PawRescue_AppleUserID"
    private let userNameKey  = "PawRescue_AppleUserName"
    private let userEmailKey = "PawRescue_AppleUserEmail"
    
    private override init() {
        super.init()
        restoreFromKeychain()
    }
    
    // MARK: - Restore Session
    
    /// Reads credentials from Keychain and restores session on re-launch.
    func restoreFromKeychain() {
        guard let savedID = keychainLoad(key: userIDKey), !savedID.isEmpty else {
            isAuthenticated = false
            return
        }
        currentUserID    = savedID
        currentUserName  = keychainLoad(key: userNameKey)  ?? ""
        currentUserEmail = keychainLoad(key: userEmailKey) ?? ""
        isAuthenticated  = true
        
        // If the saved name is generic or empty, attempt to resolve the real name in background
        if currentUserName.isEmpty || currentUserName.lowercased() == "rescuer" {
            Task {
                await resolveAndPersistRealUserName(forUserID: savedID)
            }
        }
        
        // Validate Apple ID credential state in background
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: savedID) { [weak self] state, _ in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    self?.isAuthenticated = true
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Native SwiftUI Authorization Handler
    
    func handleAuthorization(_ authorization: ASAuthorization) {
        isSigningIn = false
        signInErrorMessage = nil
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        
        let userID    = credential.user
        let firstName = credential.fullName?.givenName  ?? ""
        let lastName  = credential.fullName?.familyName ?? ""
        let fullName  = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        let cachedName = keychainLoad(key: userNameKey)
        let email     = credential.email ?? (keychainLoad(key: userEmailKey) ?? "")
        
        // Determine the best name: Apple fullName > non-generic cached name > empty
        var resolvedName = fullName
        if resolvedName.isEmpty, let cached = cachedName, !cached.isEmpty, cached.lowercased() != "rescuer" {
            resolvedName = cached
        }
        
        keychainSave(key: userIDKey, value: userID)
        if !resolvedName.isEmpty {
            keychainSave(key: userNameKey, value: resolvedName)
        }
        if !email.isEmpty {
            keychainSave(key: userEmailKey, value: email)
        }
        
        DispatchQueue.main.async {
            self.currentUserID    = userID
            self.currentUserName  = resolvedName
            self.currentUserEmail = email
            self.isAuthenticated  = true
            self.signInErrorMessage = nil
        }
        
        // If Apple didn't provide a name, discover from CloudKit / iCloud asynchronously
        Task {
            await self.resolveAndPersistRealUserName(forUserID: userID)
        }
    }
    
    func handleAuthorizationError(_ error: Error) {
        isSigningIn = false
        if let authError = error as? ASAuthorizationError {
            if authError.code == .canceled {
                signInErrorMessage = nil
                return
            }
        }
        DispatchQueue.main.async {
            self.signInErrorMessage = "Sign in failed. Please try again."
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        isAuthenticated    = false
        currentUserID      = ""
        currentUserName    = ""
        currentUserEmail   = ""
        isSigningIn        = false
        signInErrorMessage = nil
        keychainDelete(key: userIDKey)
        keychainDelete(key: userNameKey)
        keychainDelete(key: userEmailKey)
        ImageCacheManager.shared.clearAll()
    }
    
    // MARK: - Save User Profile Helpers
    
    func saveUserNameToKeychain(_ name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        currentUserName = clean
        keychainSave(key: userNameKey, value: clean)
    }
    
    func saveUserEmailToKeychain(_ email: String) {
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        currentUserEmail = clean
        keychainSave(key: userEmailKey, value: clean)
    }
    
    // MARK: - Resolve Real User Name from CloudKit / iCloud
    
    /// Discovers user's actual name from CloudKit or iCloud identity if Apple ID credential didn't provide one
    func resolveAndPersistRealUserName(forUserID userID: String) async {
        // 1. Check CloudKit UserStats record
        if let stats = try? await CloudKitManager.shared.fetchUserStats(userID: userID),
           let cloudName = stats.userName, !cloudName.isEmpty, cloudName.lowercased() != "rescuer" {
            await MainActor.run {
                self.saveUserNameToKeychain(cloudName)
                if let email = stats.userEmail, !email.isEmpty {
                    self.saveUserEmailToKeychain(email)
                }
            }
            return
        }
        
        // 2. Discover from iCloud user identity (e.g. "Aryan Kahate")
        if let iCloudName = await CloudKitManager.shared.fetchICloudUserName(), !iCloudName.isEmpty {
            await MainActor.run {
                self.saveUserNameToKeychain(iCloudName)
            }
            // Save to CloudKit for future logins across all devices
            try? await CloudKitManager.shared.saveUserStats(
                userID: userID,
                saved: 0,
                reported: 0,
                assignedCaseIDs: [],
                userName: iCloudName
            )
        }
    }
}

// MARK: - Keychain Helpers
private extension AuthManager {
    func keychainSave(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func keychainLoad(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func keychainDelete(key: String) {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
