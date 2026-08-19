import AuthenticationServices
import Security
import SwiftUI

/// Manages Sign In with Apple authentication.
/// Persists credentials in Keychain and validates state on every launch.
final class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUserName: String = ""
    @Published var currentUserEmail: String = ""
    @Published var currentUserID: String = ""
    
    // Keychain keys
    private let userIDKey    = "PawRescue_AppleUserID"
    private let userNameKey  = "PawRescue_AppleUserName"
    private let userEmailKey = "PawRescue_AppleUserEmail"
    
    private override init() {
        super.init()
        restoreFromKeychain()
    }
    
    // MARK: - Restore Session
    
    /// Reads credentials from Keychain and validates them with Apple.
    func restoreFromKeychain() {
        guard let savedID = keychainLoad(key: userIDKey) else {
            isAuthenticated = false
            return
        }
        currentUserID    = savedID
        currentUserName  = keychainLoad(key: userNameKey)  ?? ""
        currentUserEmail = keychainLoad(key: userEmailKey) ?? ""
        
        // Validate the credential state with Apple
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: savedID) { [weak self] state, _ in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    self?.isAuthenticated = true
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    self?.isAuthenticated = true // transferred/unknown — keep session
                }
            }
        }
    }
    
    // MARK: - Sign In
    
    /// Called from SignInView to trigger Sign In with Apple sheet.
    func performSignIn(anchor: ASPresentationAnchor) {
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate            = self
        controller.presentationContextProvider = self
        _presentationAnchor = anchor
        controller.performRequests()
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        isAuthenticated  = false
        currentUserID    = ""
        currentUserName  = ""
        currentUserEmail = ""
        keychainDelete(key: userIDKey)
        keychainDelete(key: userNameKey)
        keychainDelete(key: userEmailKey)
        ImageCacheManager.shared.clearAll()
    }
    
    // MARK: - Private
    private var _presentationAnchor: ASPresentationAnchor?
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        
        let userID = appleIDCredential.user
        
        // Full name is only provided on first sign-in; use cached if nil
        let firstName  = appleIDCredential.fullName?.givenName  ?? ""
        let lastName   = appleIDCredential.fullName?.familyName ?? ""
        let fullName   = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        let name       = fullName.isEmpty ? (keychainLoad(key: userNameKey) ?? "Rescuer") : fullName
        let email      = appleIDCredential.email ?? (keychainLoad(key: userEmailKey) ?? "")
        
        // Persist to Keychain
        keychainSave(key: userIDKey,    value: userID)
        keychainSave(key: userNameKey,  value: name)
        keychainSave(key: userEmailKey, value: email)
        
        DispatchQueue.main.async {
            self.currentUserID    = userID
            self.currentUserName  = name
            self.currentUserEmail = email
            self.isAuthenticated  = true
        }
    }
    
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        // User cancelled or error — stay on sign-in screen
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            print("[AuthManager] User cancelled Apple Sign In")
        } else {
            print("[AuthManager] Sign in error: \(error.localizedDescription)")
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        _presentationAnchor ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
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
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      key,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
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
