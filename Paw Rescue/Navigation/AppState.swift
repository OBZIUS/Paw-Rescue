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
    @Published var userName:  String = ""
    @Published var userRole:  String = "Animal lover | Rescuer"
    
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
            // Case 1: You reported this dog
            let isReporter = !currentUserID.isEmpty && report.reporterUserID == currentUserID
            // Case 2: You accepted to rescue this dog
            let isRescuer  = report.cloudKitRecordName.map { assignedCaseIDs.contains($0) } ?? false
            return isReporter || isRescuer
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
    
    // MARK: - Init
    init() {
        let ud = UserDefaults.standard
        // Restore persisted values from UserDefaults
        self.hasCompletedOnboarding = ud.bool(forKey: "hasCompletedOnboarding")
        self.isSignedIn             = ud.bool(forKey: "isSignedIn")
        self.dogsSavedCount         = ud.integer(forKey: "dogsSavedCount")
        self.dogsReportedCount      = ud.integer(forKey: "dogsReportedCount")
        // Restore assigned case IDs from JSON string
        if let str = ud.string(forKey: "assignedCaseIDsJSON"),
           let data = str.data(using: .utf8),
           let ids  = try? JSONDecoder().decode([String].self, from: data) {
            self.assignedCaseIDs = ids
        } else {
            self.assignedCaseIDs = []
        }
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Data Loading
    // MARK: - ─────────────────────────────────────────
    
    /// Fetches real dog reports from CloudKit public database.
    /// Call on app launch, map appear, and pull-to-refresh.
    /// NOTE: CloudKit public DB is readable without auth — no guard needed.
    func loadReports() {
        isLoadingReports = true
        Task {
            do {
                var reports = try await CloudKitManager.shared.fetchReports()
                // Re-apply local assigned state
                let ids           = self.assignedCaseIDs
                let currentUserID = AuthManager.shared.currentUserID
                for i in reports.indices {
                    if let name = reports[i].cloudKitRecordName, ids.contains(name) {
                        reports[i].isAssignedToUser = true
                    }
                    // Mark if current user is the rescuer
                    if !currentUserID.isEmpty, reports[i].rescuerUserID == currentUserID {
                        reports[i].isAssignedToUser = true
                    }
                }
                await MainActor.run {
                    self.dogReports     = reports
                    self.isLoadingReports = false
                }
            } catch {
                await MainActor.run { self.isLoadingReports = false }
                print("[AppState] Failed to fetch reports: \(error)")
            }
        }
    }
    
    /// Fetches real feed posts from CloudKit public database.
    func loadFeedPosts() {
        isLoadingFeed = true
        Task {
            do {
                let posts = try await CloudKitManager.shared.fetchFeedPosts()
                await MainActor.run {
                    self.feedPosts    = posts
                    self.isLoadingFeed = false
                }
            } catch {
                await MainActor.run { self.isLoadingFeed = false }
                print("[AppState] Failed to fetch feed: \(error)")
            }
        }
    }
    
    /// Syncs user stats FROM CloudKit private DB into AppStorage.
    /// Called on sign-in and app foreground.
    func syncUserStats(userID: String) {
        Task {
            do {
                let stats = try await CloudKitManager.shared.fetchUserStats(userID: userID)
                await MainActor.run {
                    // Only update from CloudKit if it's higher (prevents overwriting local progress on re-install)
                    self.dogsSavedCount    = max(self.dogsSavedCount,    stats.saved)
                    self.dogsReportedCount = max(self.dogsReportedCount, stats.reported)
                    // Merge assigned case IDs
                    var merged = Set(self.assignedCaseIDs)
                    merged.formUnion(stats.assignedCaseIDs)
                    self.assignedCaseIDs = Array(merged)
                }
            } catch {
                print("[AppState] Failed to sync user stats: \(error)")
            }
        }
    }
    
    /// Pushes local stats TO CloudKit private DB. Call after any stat change.
    private func pushUserStats(userID: String) {
        let saved    = dogsSavedCount
        let reported = dogsReportedCount
        let ids      = assignedCaseIDs
        Task {
            try? await CloudKitManager.shared.saveUserStats(
                userID: userID, saved: saved, reported: reported, assignedCaseIDs: ids
            )
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
        locationName: String = "Park 23, Bali"
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
        
        // Upload to CloudKit in background
        let userID = AuthManager.shared.currentUserID
        Task {
            do {
                let uploaded = try await CloudKitManager.shared.saveReport(newReport)
                await MainActor.run {
                    // Backfill the cloudKitRecordName into the local copy
                    if let idx = self.dogReports.firstIndex(where: { $0.id == newReport.id }) {
                        self.dogReports[idx].cloudKitRecordName = uploaded.cloudKitRecordName
                    }
                    if self.lastSubmittedReport?.id == newReport.id {
                        self.lastSubmittedReport?.cloudKitRecordName = uploaded.cloudKitRecordName
                    }
                    if !userID.isEmpty {
                        self.pushUserStats(userID: userID)
                    }
                }
            } catch {
                print("[AppState] Failed to upload report: \(error)")
            }
        }
        
        return newReport
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Feed Post
    // MARK: - ─────────────────────────────────────────
    
    /// Adds a post locally and uploads to CloudKit in background.
    func addFeedPost(image: UIImage?, images: [UIImage] = [], caption: String, isAnonymous: Bool) {
        let allImages = images.isEmpty ? (image != nil ? [image!] : []) : images
        let postUsername = isAnonymous
            ? "anonymous_rescuer"
            : (userName.isEmpty ? "rescuer" : userName.lowercased().replacingOccurrences(of: " ", with: "_") + "_rescuer")
        
        var newPost = FeedPost(
            userID:   isAnonymous ? nil : AuthManager.shared.currentUserID,
            username: postUsername,
            dogImage: allImages.first,
            images:   allImages,
            caption:  caption,
            likeCount: 0,
            timeAgo:  "Just now"
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
    
    func updateReport(reportId: UUID, newDescription: String? = nil, newCoordinate: CLLocationCoordinate2D? = nil, newLocationName: String? = nil) {
        if let index = dogReports.firstIndex(where: { $0.id == reportId }) {
            if let newDescription  = newDescription  { dogReports[index].description = newDescription }
            if let newCoordinate   = newCoordinate   { dogReports[index].coordinate  = newCoordinate }
            if let newLocationName = newLocationName { dogReports[index].location    = newLocationName }
        }
    }
    
    func updateReportDescription(reportId: UUID, newDescription: String) {
        if let index = dogReports.firstIndex(where: { $0.id == reportId }) {
            dogReports[index].description = newDescription
        }
    }
    
    /// Assigns a case to the current user.
    /// Persists locally + CloudKit private DB (stats) + writes rescuer name to public DB record.
    func assignCaseToUser(reportId: UUID) {
        guard let index = dogReports.firstIndex(where: { $0.id == reportId }) else { return }
        let userID      = AuthManager.shared.currentUserID
        let displayName = AuthManager.shared.currentUserName
        
        dogReports[index].isAssignedToUser = true
        dogReports[index].rescuerUserID    = userID
        dogReports[index].rescuerName      = displayName
        
        if let recordName = dogReports[index].cloudKitRecordName, !assignedCaseIDs.contains(recordName) {
            assignedCaseIDs.append(recordName)
            if !userID.isEmpty { pushUserStats(userID: userID) }
            
            // Write rescuer info to the CloudKit public record so the reporter sees it
            if !userID.isEmpty && !displayName.isEmpty {
                Task {
                    try? await CloudKitManager.shared.acceptCase(
                        recordName: recordName,
                        rescuerUserID: userID,
                        rescuerName: displayName
                    )
                }
            }
        }
    }
    
    /// Unassigns a case. Persists locally and to CloudKit private DB.
    func unassignCase(reportId: UUID) {
        if let index = dogReports.firstIndex(where: { $0.id == reportId }) {
            dogReports[index].isAssignedToUser = false
            if let name = dogReports[index].cloudKitRecordName {
                assignedCaseIDs.removeAll { $0 == name }
                let userID = AuthManager.shared.currentUserID
                if !userID.isEmpty { pushUserStats(userID: userID) }
            }
        }
    }
    
    /// Marks a case as done, increments stats, and syncs to CloudKit.
    func markCaseDone(reportId: UUID) {
        if let index = dogReports.firstIndex(where: { $0.id == reportId }) {
            guard !dogReports[index].isCompleted else { return }
            dogReports[index].isCompleted      = true
            dogReports[index].isAssignedToUser = false
            dogsSavedCount += 1
            
            if let name = dogReports[index].cloudKitRecordName {
                assignedCaseIDs.removeAll { $0 == name }
                // Mark completed on CloudKit public DB
                Task { try? await CloudKitManager.shared.markReportCompleted(recordName: name) }
            }
            
            let userID = AuthManager.shared.currentUserID
            if !userID.isEmpty { pushUserStats(userID: userID) }
        }
    }
    
    // MARK: - Private Helpers
    private func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }
}
