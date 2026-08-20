import SwiftUI
import CoreLocation

/// Central observable app state — backed by CloudKit (public + private DB) and UserDefaults.
/// All data persists across launches and is shared in real-time between devices.
final class AppState: ObservableObject {
    enum Tab: String {
        case home = "Home"
        case map  = "Map"
    }
    
    @Published var selectedTab: Tab = .map
    
    // MARK: - Persistent Flags (survive app kill / reinstall on same Apple ID)
    // Note: @AppStorage doesn't fire objectWillChange in ObservableObject, so we
    // use @Published + UserDefaults directly for correct SwiftUI reactivity.
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var isSignedIn: Bool {
        didSet { UserDefaults.standard.set(isSignedIn, forKey: "isSignedIn") }
    }
    
    // MARK: - Profile (driven by AuthManager + CloudKit private DB)
    @Published var userName:  String = "" {
        didSet { UserDefaults.standard.set(userName, forKey: "savedUserName") }
    }
    @Published var userRole:  String = "Animal lover | Rescuer" {
        didSet { UserDefaults.standard.set(userRole, forKey: "savedUserRole") }
    }
    
    // Stats — @Published + UserDefaults for instant display + persistence
    @Published var dogsSavedCount: Int {
        didSet { UserDefaults.standard.set(dogsSavedCount, forKey: "dogsSavedCount") }
    }
    @Published var dogsReportedCount: Int {
        didSet { UserDefaults.standard.set(dogsReportedCount, forKey: "dogsReportedCount") }
    }
    
    // Assigned case IDs — JSON-encoded in UserDefaults + synced to CloudKit private DB
    @Published var assignedCaseIDs: [String] {
        didSet {
            if let data = try? JSONEncoder().encode(assignedCaseIDs),
               let str = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(str, forKey: "assignedCaseIDsJSON")
            }
        }
    }
    
    // MARK: - Completed Case Record Names (Set of record names/IDs marked done)
    @Published var completedCaseRecordNames: Set<String> = []
    
    // MARK: - Live Reports & Map Pins (from CloudKit public DB)
    @Published var dogReports: [DogReport] = []
    
    // MARK: - User GPS Coordinate
    @Published var userCurrentCoordinate: CLLocationCoordinate2D = MockData.kutaCenter
    
    // MARK: - User Activity (Your Activity carousel)
    // Shows: dogs YOU reported (so you track your own reports) + dogs you accepted to rescue
    var userActivityReports: [DogReport] {
        let currentUserID = AuthManager.shared.currentUserID
        return dogReports.filter { report in
            guard !report.isCompleted else { return false }
            if let name = report.cloudKitRecordName, completedCaseRecordNames.contains(name) { return false }
            if completedCaseRecordNames.contains(report.id.uuidString) { return false }
            // Case 1: You reported this dog
            let isReporter = !currentUserID.isEmpty && report.reporterUserID == currentUserID
            // Case 2: You accepted to rescue this dog (check both local IDs and CloudKit rescuerUserID)
            let assignedByLocalID = report.cloudKitRecordName.map { assignedCaseIDs.contains($0) } ?? false
            let assignedByCloudKit = !currentUserID.isEmpty && report.rescuerUserID == currentUserID
            return isReporter || assignedByLocalID || assignedByCloudKit
        }
    }
    
    // MARK: - Feed Posts (from CloudKit public DB)
    @Published var feedPosts: [FeedPost] = []
    
    // MARK: - Report Flow State
    @Published var isShowingReportFlow: Bool = false
    @Published var currentFormData: ReportFormData = ReportFormData()
    @Published var lastSubmittedReport: DogReport?
    
    // MARK: - Loading State
    @Published var isLoadingReports:   Bool = false
    @Published var isLoadingFeed:      Bool = false
    
    // MARK: - Global Reset Cutoff (August 20, 2026 21:12:00 UTC+8)
    private static let globalResetCutoffTimestamp: TimeInterval = 1771506720
    
    // MARK: - Init
    init() {
        let ud = UserDefaults.standard
        
        self.hasCompletedOnboarding = ud.bool(forKey: "hasCompletedOnboarding")
        self.isSignedIn             = ud.bool(forKey: "isSignedIn")
        self.userName               = ud.string(forKey: "savedUserName") ?? ""
        self.userRole               = ud.string(forKey: "savedUserRole") ?? "Animal lover | Rescuer"
        self.dogReports             = []
        self.feedPosts              = []
        self.assignedCaseIDs        = []
        self.completedCaseRecordNames = []
        
        // ── HARD FRESH START (cache only — stats are preserved) ──────────────
        // Wipe local report/feed caches so the app fetches fresh from CloudKit.
        ud.removeObject(forKey: "cachedDogReportsJSON")
        ud.removeObject(forKey: "assignedCaseIDsJSON")
        ud.removeObject(forKey: "completedCaseRecordNamesJSON")
        ImageCacheManager.shared.clearAll()
        
        // Restore stats from UserDefaults (written by markCaseDone / pushUserStats)
        self.dogsSavedCount    = ud.integer(forKey: "dogsSavedCount")
        self.dogsReportedCount = ud.integer(forKey: "dogsReportedCount")
        
        // One-time CloudKit wipe (runs once per fresh install key)
        let freshStartKey = "didWipeCloudForFreshStart_v3"
        if !ud.bool(forKey: freshStartKey) {
            ud.set(true, forKey: freshStartKey)
            ud.set(0, forKey: "dogsSavedCount")
            ud.set(0, forKey: "dogsReportedCount")
            self.dogsSavedCount    = 0
            self.dogsReportedCount = 0
            Task {
                await CloudKitManager.shared.deleteAllReportsFromCloud()
                await CloudKitManager.shared.deleteAllFeedPostsFromCloud()
            }
        }
        // ─────────────────────────────────────────────────────────────────────
        
        // Start automatic live sync timer (reports every 3s, feed every 6s)
        startRealtimeSyncTimer()
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Master Reset / Wipe All Data
    // MARK: - ─────────────────────────────────────────
    
    /// Clears all dog pins, posts, rescued/reported stats across CloudKit public DB, private DB, and local storage.
    func wipeAllDataAndResetCloud() {
        self.dogReports = []
        self.feedPosts = []
        self.dogsSavedCount = 0
        self.dogsReportedCount = 0
        self.assignedCaseIDs = []
        self.completedCaseRecordNames = []
        self.lastSubmittedReport = nil
        
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "cachedDogReportsJSON")
        ud.removeObject(forKey: "assignedCaseIDsJSON")
        ud.removeObject(forKey: "completedCaseRecordNamesJSON")
        ud.set(0, forKey: "dogsSavedCount")
        ud.set(0, forKey: "dogsReportedCount")
        
        ImageCacheManager.shared.clearAll()
        
        let userID = AuthManager.shared.currentUserID
        Task {
            await CloudKitManager.shared.deleteAllReportsFromCloud()
            await CloudKitManager.shared.deleteAllFeedPostsFromCloud()
            if !userID.isEmpty {
                await CloudKitManager.shared.resetUserStatsInCloud(userID: userID)
            }
        }
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Real-Time Background Sync
    // MARK: - ─────────────────────────────────────────
    
    private var syncTimer: Timer?
    private var isSyncingReports = false
    private var isSyncingFeed = false
    
    private var feedSyncTickCount = 0
    
    /// Starts polling CloudKit every 8 seconds for reports, and every 16 seconds for feed.
    /// Slower interval prevents constant full-array replacements that cause UI jitter.
    func startRealtimeSyncTimer() {
        syncTimer?.invalidate()
        feedSyncTickCount = 0
        syncTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.loadReports(isBackgroundSync: true)
                self.feedSyncTickCount += 1
                if self.feedSyncTickCount % 2 == 0 {
                    self.loadFeedPosts(isBackgroundSync: true)
                }
            }
        }
    }
    
    func stopRealtimeSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Data Loading
    // MARK: - ─────────────────────────────────────────
    
    /// Fetches live dog reports from CloudKit public database and updates the map pins.
    func loadReports(isBackgroundSync: Bool = false) {
        if isSyncingReports { return }
        isSyncingReports = true
        if !isBackgroundSync {
            isLoadingReports = true
        }
        Task {
            defer {
                Task { @MainActor in
                    self.isSyncingReports = false
                }
            }
            do {
                var reports = try await CloudKitManager.shared.fetchReports()
                
                // Discard any legacy records created before the global reset timestamp
                reports.removeAll { report in
                    if let creation = report.creationDate, creation.timeIntervalSince1970 < Self.globalResetCutoffTimestamp {
                        return true
                    }
                    return false
                }
                
                // Re-apply CloudKit assigned and completed states
                let currentUserID = AuthManager.shared.currentUserID
                for i in reports.indices {
                    let recordName = reports[i].cloudKitRecordName
                    
                    // 1. Completed state sync — propagate cloud isCompleted into local set
                    //    so ALL users (including the reporter) see it cleared from activity
                    if reports[i].isCompleted ||
                       (recordName != nil && self.completedCaseRecordNames.contains(recordName!)) ||
                       self.completedCaseRecordNames.contains(reports[i].id.uuidString) {
                        reports[i].isCompleted = true
                        reports[i].isAssignedToUser = false
                        // Persist into local set so userActivityReports filter works immediately
                        if let name = recordName {
                            self.completedCaseRecordNames.insert(name)
                        }
                    }
                    
                    // 2. Rescuer / Assignment state sync
                    if let rescuerUID = reports[i].rescuerUserID, !rescuerUID.isEmpty {
                        if !currentUserID.isEmpty && rescuerUID == currentUserID {
                            reports[i].isAssignedToUser = !reports[i].isCompleted
                        } else {
                            // Another user is the rescuer — pin turns blue for everyone
                            reports[i].isAssignedToUser = false
                        }
                    } else {
                        // Open case — unassigned for everyone
                        reports[i].rescuerUserID = nil
                        reports[i].rescuerName   = nil
                        reports[i].isAssignedToUser = false
                        if let name = recordName {
                            self.assignedCaseIDs.removeAll { $0 == name }
                        }
                    }
                }
                
                // Merge any newly submitted local reports that haven't synced yet
                let cloudRecordNames = Set(reports.compactMap { $0.cloudKitRecordName })
                for local in self.dogReports {
                    if let recordName = local.cloudKitRecordName {
                        if !cloudRecordNames.contains(recordName) && !local.isCompleted && !self.completedCaseRecordNames.contains(recordName) {
                            reports.insert(local, at: 0)
                        }
                    } else if !local.isCompleted && !self.completedCaseRecordNames.contains(local.id.uuidString) {
                        reports.insert(local, at: 0)
                    }
                }
                
                await MainActor.run {
                    // Smart diff: only replace array when content actually changed
                    // (avoids full SwiftUI re-render of map + home every 8 seconds)
                    let newIDs = reports.map { $0.cloudKitRecordName ?? $0.id.uuidString }
                    let oldIDs = self.dogReports.map { $0.cloudKitRecordName ?? $0.id.uuidString }
                    let newCompleted = reports.map { $0.isCompleted }
                    let oldCompleted = self.dogReports.map { $0.isCompleted }
                    let newRescuers  = reports.map { $0.rescuerUserID ?? "" }
                    let oldRescuers  = self.dogReports.map { $0.rescuerUserID ?? "" }
                    if newIDs != oldIDs || newCompleted != oldCompleted || newRescuers != oldRescuers {
                        self.dogReports = reports
                        Self.saveCachedReports(reports)
                    }
                    if !isBackgroundSync {
                        self.isLoadingReports = false
                    }
                }
            } catch {
                if !isBackgroundSync {
                    await MainActor.run { self.isLoadingReports = false }
                }
                print("[AppState] Failed to fetch reports from CloudKit: \(error.localizedDescription)")
            }
        }
    }
    
    /// Fetches real feed posts from CloudKit public database.
    func loadFeedPosts(isBackgroundSync: Bool = false) {
        if isSyncingFeed { return }
        isSyncingFeed = true
        if !isBackgroundSync {
            isLoadingFeed = true
        }
        Task {
            defer {
                Task { @MainActor in
                    self.isSyncingFeed = false
                }
            }
            do {
                var posts = try await CloudKitManager.shared.fetchFeedPosts()
                
                // Discard any legacy feed posts created before the global reset timestamp
                posts.removeAll { post in
                    if let creation = post.creationDate, creation.timeIntervalSince1970 < Self.globalResetCutoffTimestamp {
                        return true
                    }
                    return false
                }
                
                await MainActor.run {
                    self.feedPosts    = posts
                    if !isBackgroundSync {
                        self.isLoadingFeed = false
                    }
                }
            } catch {
                if !isBackgroundSync {
                    await MainActor.run { self.isLoadingFeed = false }
                }
                print("[AppState] Failed to fetch feed: \(error)")
            }
        }
    }
    
    /// Syncs user stats and profile FROM CloudKit private DB into AppStorage.
    /// Called on sign-in and app foreground.
    func syncUserStats(userID: String) {
        Task {
            do {
                let stats = try await CloudKitManager.shared.fetchUserStats(userID: userID)
                await MainActor.run {
                    self.dogsSavedCount    = max(self.dogsSavedCount,    stats.saved)
                    self.dogsReportedCount = max(self.dogsReportedCount, stats.reported)
                    var merged = Set(self.assignedCaseIDs)
                    merged.formUnion(stats.assignedCaseIDs)
                    self.assignedCaseIDs = Array(merged)
                    
                    // Sync profile name and role if present in CloudKit
                    if let cloudName = stats.userName, !cloudName.isEmpty, cloudName.lowercased() != "rescuer" {
                        self.userName = cloudName
                        AuthManager.shared.saveUserNameToKeychain(cloudName)
                    }
                    if let cloudRole = stats.userRole, !cloudRole.isEmpty {
                        self.userRole = cloudRole
                    }
                    if let cloudEmail = stats.userEmail, !cloudEmail.isEmpty {
                        AuthManager.shared.saveUserEmailToKeychain(cloudEmail)
                    }
                }
            } catch {
                print("[AppState] Failed to sync user stats: \(error)")
            }
        }
    }
    
    /// Updates user's display name and role across AppState, AuthManager, Keychain, and CloudKit.
    func updateUserProfile(name: String, role: String, email: String? = nil) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanRole = role.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanName.isEmpty {
            self.userName = cleanName
            AuthManager.shared.saveUserNameToKeychain(cleanName)
        }
        if !cleanRole.isEmpty {
            self.userRole = cleanRole
        }
        if let email = email, !email.isEmpty {
            AuthManager.shared.saveUserEmailToKeychain(email)
        }
        
        let userID = AuthManager.shared.currentUserID
        if !userID.isEmpty {
            pushUserStats(userID: userID)
        }
    }
    
    private var statsPushTask: Task<Void, Never>?

    /// Pushes local stats and profile TO CloudKit private DB. Call after any profile/stat change.
    func pushUserStats(userID: String) {
        let saved = dogsSavedCount, reported = dogsReportedCount
        let ids = assignedCaseIDs, name = userName, role = userRole
        let email = AuthManager.shared.currentUserEmail
        let previous = statsPushTask
        statsPushTask = Task {
            _ = await previous?.value
            do {
                try await CloudKitManager.shared.saveUserStats(
                    userID: userID, saved: saved, reported: reported,
                    assignedCaseIDs: ids, userName: name, userEmail: email, userRole: role
                )
            } catch {
                print("[AppState] pushUserStats failed: \(error)")
            }
        }
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Navigation Helpers
    // MARK: - ─────────────────────────────────────────
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func signIn() {
        isSignedIn = true
    }
    
    func signOut() {
        isSignedIn = false
        // Clear in-memory data (AppStorage flags and stats are kept)
        dogReports = []
        feedPosts  = []
        lastSubmittedReport = nil
        AuthManager.shared.signOut()
    }
    
    func startReportFlow() {
        currentFormData = ReportFormData()
        lastSubmittedReport = nil
        isShowingReportFlow = true
    }
    
    func finishReportFlow() {
        isShowingReportFlow = false
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Report Submission
    // MARK: - ─────────────────────────────────────────
    
    /// Creates a report locally (for instant map display) and uploads to CloudKit in background.
    func submitReport(
        formData: ReportFormData,
        customCoordinate: CLLocationCoordinate2D? = nil,
        locationName: String = "Kuta, Bali"
    ) -> DogReport {
        let urgency = formData.calculatedUrgency
        
        var symptoms: [Symptom] = []
        if let wound = formData.woundStatus, wound.contains("bleeding") && !wound.contains("no wound") {
            symptoms.append(Symptom(name: "Bleeding", iconName: "drop.fill"))
        }
        if let mobility = formData.mobilityStatus, mobility.contains("Struggles") || mobility.contains("Can't move") {
            symptoms.append(Symptom(name: "Limping", iconName: "figure.walk"))
        }
        for cue in formData.visualCues {
            if cue.contains("Ribs") {
                symptoms.append(Symptom(name: "Malnourished", iconName: "exclamationmark.triangle.fill"))
            } else if cue.contains("Bald") || cue.contains("Crusty") {
                symptoms.append(Symptom(name: "Skin Issue", iconName: "allergens"))
            }
        }
        if symptoms.isEmpty {
            symptoms.append(Symptom(name: "Needs Care", iconName: "heart.fill"))
        }
        
        let reportNumber = dogReports.count + 1
        let reportCoord  = customCoordinate ?? CLLocationCoordinate2D(
            latitude:  userCurrentCoordinate.latitude  + Double.random(in: -0.0008...0.0008),
            longitude: userCurrentCoordinate.longitude + Double.random(in: -0.0008...0.0008)
        )
        
        var newReport = DogReport(
            id: UUID(),
            reporterUserID: AuthManager.shared.currentUserID,
            title: "DOG #\(reportNumber)",
            customImage: formData.photos.first,
            photos: formData.photos,
            reporterName: userName.isEmpty ? "Anonymous" : userName,
            timeReported: "Just now",
            dateFormatted: formattedCurrentDate(),
            location: locationName,
            distance: "Near you",
            coordinate: reportCoord,
            urgency: urgency,
            description: formData.additionalDescription.isEmpty
                ? "Found near \(locationName) needing rescue and care."
                : formData.additionalDescription,
            symptoms: symptoms,
            isAssignedToUser: false,
            isCompleted: false
        )
        
        // Insert locally for instant map update
        dogReports.insert(newReport, at: 0)
        dogsReportedCount += 1
        lastSubmittedReport = newReport
        Self.saveCachedReports(dogReports)
        
        // Upload to CloudKit in background
        let userID = AuthManager.shared.currentUserID
        Task {
            do {
                let uploaded = try await CloudKitManager.shared.saveReport(newReport)
                await MainActor.run {
                    // Backfill the cloudKitRecordName into the local copy
                    if let idx = self.dogReports.firstIndex(where: { $0.id == newReport.id }) {
                        self.dogReports[idx].cloudKitRecordName = uploaded.cloudKitRecordName
                        self.dogReports[idx].creationDate = uploaded.creationDate
                    }
                    if self.lastSubmittedReport?.id == newReport.id {
                        self.lastSubmittedReport?.cloudKitRecordName = uploaded.cloudKitRecordName
                    }
                    Self.saveCachedReports(self.dogReports)
                    if !userID.isEmpty {
                        self.pushUserStats(userID: userID)
                    }
                }
            } catch {
                print("[AppState] Failed to upload report to CloudKit: \(error.localizedDescription) - Details: \(error)")
            }
        }
        
        return newReport
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Feed Post
    // MARK: - ─────────────────────────────────────────
    
    /// Adds a post locally and uploads to CloudKit in background.
    func addFeedPost(
        image: UIImage?,
        images: [UIImage] = [],
        caption: String,
        isAnonymous: Bool,
        reporterUserID: String? = nil,
        reporterUsername: String? = nil
    ) {
        let allImages = images.isEmpty ? (image != nil ? [image!] : []) : images
        let postUsername = isAnonymous
            ? "anonymous_rescuer"
            : (userName.isEmpty ? "rescuer" : userName.lowercased().replacingOccurrences(of: " ", with: "_") + "_rescuer")
        
        let helperID = isAnonymous ? nil : AuthManager.shared.currentUserID
        
        var newPost = FeedPost(
            userID:           helperID,
            username:         postUsername,
            helperUserID:     helperID,
            helperUsername:   postUsername,
            reporterUserID:   reporterUserID,
            reporterUsername: reporterUsername,
            dogImage:         allImages.first,
            images:           allImages,
            caption:          caption,
            likeCount:        0,
            timeAgo:          "Just now"
        )
        
        // Insert locally for instant display
        feedPosts.insert(newPost, at: 0)
        
        // Upload to CloudKit in background
        Task {
            do {
                let uploaded = try await CloudKitManager.shared.saveFeedPost(newPost)
                await MainActor.run {
                    if let idx = self.feedPosts.firstIndex(where: { $0.id == newPost.id }) {
                        self.feedPosts[idx].cloudKitRecordName = uploaded.cloudKitRecordName
                    }
                }
            } catch {
                print("[AppState] Failed to upload feed post: \(error)")
            }
        }
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Like Toggle
    // MARK: - ─────────────────────────────────────────
    
    /// Toggles like locally for instant UI, then syncs to CloudKit.
    func toggleLike(postId: UUID) {
        guard let idx = feedPosts.firstIndex(where: { $0.id == postId }) else { return }
        let wasLiked       = feedPosts[idx].isLiked
        let recordName     = feedPosts[idx].cloudKitRecordName
        feedPosts[idx].isLiked.toggle()
        feedPosts[idx].likeCount += wasLiked ? -1 : 1
        feedPosts[idx].likeCount = max(0, feedPosts[idx].likeCount)
        
        guard let recordName = recordName, !AuthManager.shared.currentUserID.isEmpty else { return }
        let userID = AuthManager.shared.currentUserID
        Task {
            do {
                let newCount = try await CloudKitManager.shared.toggleLike(
                    postRecordName: recordName, userID: userID, currentlyLiked: wasLiked
                )
                await MainActor.run {
                    if let i = self.feedPosts.firstIndex(where: { $0.id == postId }) {
                        self.feedPosts[i].likeCount = newCount
                    }
                }
            } catch {
                print("[AppState] Failed to sync like: \(error)")
                // Revert local optimistic update on failure
                await MainActor.run {
                    if let i = self.feedPosts.firstIndex(where: { $0.id == postId }) {
                        self.feedPosts[i].isLiked  = wasLiked
                        self.feedPosts[i].likeCount += wasLiked ? 1 : -1
                    }
                }
            }
        }
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Case Assignment
    // MARK: - ─────────────────────────────────────────
    
    /// Robust helper to locate a report in dogReports by recordName or ID.
    func findReportIndex(id: UUID? = nil, cloudKitRecordName: String? = nil) -> Int? {
        if let recordName = cloudKitRecordName, !recordName.isEmpty {
            if let idx = dogReports.firstIndex(where: { $0.cloudKitRecordName == recordName }) {
                return idx
            }
        }
        if let id = id {
            return dogReports.firstIndex(where: { $0.id == id || $0.cloudKitRecordName == id.uuidString })
        }
        return nil
    }

    /// Updates the description of a report in place.
    func updateReportDescription(reportId: UUID, newDescription: String, recordName: String? = nil) {
        if let index = findReportIndex(id: reportId, cloudKitRecordName: recordName) {
            dogReports[index].description = newDescription
            Self.saveCachedReports(dogReports)
        }
    }
    
    /// Assigns a case to the current user.
    /// Persists locally + CloudKit private DB (stats) + writes rescuer name to public DB record.
    func assignCaseToUser(reportId: UUID, recordName: String? = nil) {
        let index = findReportIndex(id: reportId, cloudKitRecordName: recordName)
        let resolvedRecordName = recordName ?? (index != nil ? dogReports[index!].cloudKitRecordName : nil)
        let userID      = AuthManager.shared.currentUserID
        let displayName = AuthManager.shared.currentUserName.isEmpty ? "Rescuer" : AuthManager.shared.currentUserName
        
        if let idx = index {
            dogReports[idx].isAssignedToUser = true
            dogReports[idx].rescuerUserID    = userID
            dogReports[idx].rescuerName      = displayName
        }
        
        if let recName = resolvedRecordName, !recName.isEmpty {
            if !assignedCaseIDs.contains(recName) {
                assignedCaseIDs.append(recName)
            }
            if !userID.isEmpty { pushUserStats(userID: userID) }
            
            // Write rescuer info to CloudKit public record so all devices see the case as assigned
            Task {
                do {
                    try await CloudKitManager.shared.acceptCase(
                        recordName: recName,
                        rescuerUserID: userID,
                        rescuerName: displayName
                    )
                    print("[AppState] Successfully accepted case \(recName) on CloudKit")
                } catch {
                    print("[AppState] Failed to accept case \(recName) on CloudKit: \(error)")
                }
            }
        }
        Self.saveCachedReports(dogReports)
    }
    
    /// Unassigns a case. Clears rescuer info locally and in CloudKit public DB so all devices see the pin open again.
    func unassignCase(reportId: UUID, recordName: String? = nil) {
        let index = findReportIndex(id: reportId, cloudKitRecordName: recordName)
        let resolvedRecordName = recordName ?? (index != nil ? dogReports[index!].cloudKitRecordName : nil)
        
        if let idx = index {
            dogReports[idx].isAssignedToUser = false
            dogReports[idx].rescuerUserID    = nil
            dogReports[idx].rescuerName      = nil
        }
        
        if let recName = resolvedRecordName, !recName.isEmpty {
            assignedCaseIDs.removeAll { $0 == recName }
            let userID = AuthManager.shared.currentUserID
            if !userID.isEmpty { pushUserStats(userID: userID) }
            
            // Clear rescuer info on CloudKit public database
            Task {
                do {
                    try await CloudKitManager.shared.unacceptCase(recordName: recName)
                    print("[AppState] Successfully unaccepted case \(recName) on CloudKit")
                } catch {
                    print("[AppState] Failed to unaccept case \(recName) on CloudKit: \(error)")
                }
            }
        }
        assignedCaseIDs.removeAll { $0 == reportId.uuidString }
        Self.saveCachedReports(dogReports)
    }
    
    /// Marks a case as done, increments stats, removes from map/activity, and syncs to CloudKit for all users.
    func markCaseDone(reportId: UUID, recordName: String? = nil) {
        let index = findReportIndex(id: reportId, cloudKitRecordName: recordName)
        let resolvedRecordName = recordName ?? (index != nil ? dogReports[index!].cloudKitRecordName : nil)
        let userID      = AuthManager.shared.currentUserID
        let displayName = AuthManager.shared.currentUserName
        
        if let idx = index {
            guard !dogReports[idx].isCompleted else { return }
            dogReports[idx].isCompleted      = true
            dogReports[idx].isAssignedToUser = false
            if dogReports[idx].rescuerUserID == nil || dogReports[idx].rescuerUserID?.isEmpty == true {
                dogReports[idx].rescuerUserID = userID
                dogReports[idx].rescuerName   = displayName.isEmpty ? "You" : displayName
            }
        }
        dogsSavedCount += 1
        
        if let recName = resolvedRecordName, !recName.isEmpty {
            completedCaseRecordNames.insert(recName)
            assignedCaseIDs.removeAll { $0 == recName }
            // Mark completed on CloudKit public DB
            Task {
                do {
                    try await CloudKitManager.shared.markReportCompleted(
                        recordName: recName,
                        rescuerUserID: userID,
                        rescuerName: displayName.isEmpty ? "Rescuer" : displayName
                    )
                    print("[AppState] Successfully marked CloudKit report \(recName) completed")
                } catch {
                    print("[AppState] Failed to mark CloudKit report \(recName) completed: \(error)")
                }
            }
        }
        completedCaseRecordNames.insert(reportId.uuidString)
        UserDefaults.standard.set(Array(completedCaseRecordNames), forKey: "completedCaseRecordNamesJSON")
        assignedCaseIDs.removeAll { $0 == reportId.uuidString }
        
        // Persist locally so pin is removed and activity is cleared instantly
        Self.saveCachedReports(dogReports)
        
        if !userID.isEmpty { pushUserStats(userID: userID) }
    }
    
    // MARK: - Private Helpers
    private func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    // MARK: - Disk Cache for Instant Offline Persistence
    private static func saveCachedReports(_ reports: [DogReport]) {
        let cached = reports.map { r in
            CachedDogReport(
                id: r.id,
                cloudKitRecordName: r.cloudKitRecordName,
                reporterUserID: r.reporterUserID,
                rescuerUserID: r.rescuerUserID,
                rescuerName: r.rescuerName,
                title: r.title,
                reporterName: r.reporterName,
                timeReported: r.timeReported,
                dateFormatted: r.dateFormatted,
                location: r.location,
                distance: r.distance,
                latitude: r.coordinate.latitude,
                longitude: r.coordinate.longitude,
                urgencyRaw: r.urgency.rawValue,
                description: r.description,
                symptoms: r.symptoms,
                isAssignedToUser: r.isAssignedToUser,
                isCompleted: r.isCompleted,
                creationDate: r.creationDate
            )
        }
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: "cachedDogReportsJSON")
        }
    }
    
    private static func loadCachedReports() -> [DogReport] {
        guard let data = UserDefaults.standard.data(forKey: "cachedDogReportsJSON"),
              let cached = try? JSONDecoder().decode([CachedDogReport].self, from: data) else {
            return []
        }
        return cached.map { c in
            DogReport(
                id: c.id,
                cloudKitRecordName: c.cloudKitRecordName,
                reporterUserID: c.reporterUserID,
                rescuerUserID: c.rescuerUserID,
                rescuerName: c.rescuerName,
                title: c.title,
                reporterName: c.reporterName,
                timeReported: c.timeReported,
                dateFormatted: c.dateFormatted,
                location: c.location,
                distance: c.distance,
                coordinate: CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude),
                urgency: UrgencyLevel(rawValue: c.urgencyRaw) ?? .medium,
                description: c.description,
                symptoms: c.symptoms,
                isAssignedToUser: c.isAssignedToUser,
                isCompleted: c.isCompleted,
                creationDate: c.creationDate
            )
        }
    }
}

// MARK: - Cached Report Representation
struct CachedDogReport: Codable {
    let id: UUID
    let cloudKitRecordName: String?
    let reporterUserID: String?
    let rescuerUserID: String?
    let rescuerName: String?
    let title: String
    let reporterName: String
    let timeReported: String
    let dateFormatted: String
    let location: String
    let distance: String
    let latitude: Double
    let longitude: Double
    let urgencyRaw: String
    let description: String
    let symptoms: [Symptom]
    let isAssignedToUser: Bool
    let isCompleted: Bool
    let creationDate: Date?
}
