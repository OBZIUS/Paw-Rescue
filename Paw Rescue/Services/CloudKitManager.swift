import CloudKit
import UIKit
import CoreLocation

// MARK: - CloudKit Record Type Names
/// Renamed from CKRecordType to avoid conflict with CloudKit's own CKRecord.RecordType alias.
enum PawRecordType {
    static let dogReport = "DogReport"
    static let feedPost  = "FeedPost"
    static let userStats = "UserStats"
}

enum CKReportField {
    static let title          = "title"
    static let reporterName   = "reporterName"
    static let reporterUserID = "reporterUserID"
    static let rescuerUserID  = "rescuerUserID"  // set when someone accepts the case
    static let rescuerName    = "rescuerName"    // display name of rescuer
    static let timeReported   = "timeReported"
    static let dateFormatted  = "dateFormatted"
    static let location       = "location"
    static let distance       = "distance"
    static let latitude       = "latitude"
    static let longitude      = "longitude"
    static let urgencyRaw     = "urgencyRaw"
    static let description    = "description"
    static let symptomsJSON   = "symptomsJSON"
    static let photos         = "photos"       // [CKAsset]
    static let thumbnailData  = "thumbnailData" // Data (instant 0ms thumbnail)
    static let isCompleted    = "isCompleted"
}

enum CKFeedField {
    static let username         = "username"
    static let userID           = "userID"
    static let helperUserID     = "helperUserID"
    static let helperUsername   = "helperUsername"
    static let reporterUserID   = "reporterUserID"
    static let reporterUsername = "reporterUsername"
    static let caption          = "caption"
    static let likeCount        = "likeCount"
    static let likedByUsers     = "likedByUsers"  // [String] user IDs
    static let images           = "images"        // [CKAsset]
    static let thumbnailData    = "thumbnailData" // Data (instant 0ms thumbnail)
    static let timeAgo          = "timeAgo"
    static let createdAt        = "createdAt"
}

enum CKStatsField {
    static let userID          = "userID"
    static let userName        = "userName"
    static let userEmail       = "userEmail"
    static let userRole        = "userRole"
    static let dogsSaved       = "dogsSaved"
    static let dogsReported    = "dogsReported"
    static let assignedCaseIDs = "assignedCaseIDs"  // [String] record names
}

// MARK: - CloudKitManager

/// Singleton managing all CloudKit reads and writes for Paw Rescue.
/// Uses the PUBLIC database for dog reports and feed posts (visible to all users),
/// and the PRIVATE database for per-user stats and assigned cases.
final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    // MARK: - Container & Databases
    /// Replace "iCloud.com.pawrescue.app" with your actual container ID set in Xcode.
    private let container: CKContainer
    private var publicDB:  CKDatabase { container.publicCloudDatabase  }
    private var privateDB: CKDatabase { container.privateCloudDatabase }
    
    // MARK: - State
    @Published var isFetching: Bool = false
    @Published var lastError: String?
    
    private init() {
        // Automatically connects to the app's default iCloud container configured in Xcode
        container = CKContainer.default()
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Dog Reports (Public DB)
    // MARK: - ─────────────────────────────────────────
    
    /// Fetches all dog reports from the public database, sorted newest first.
    func fetchReports() async throws -> [DogReport] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PawRecordType.dogReport, predicate: predicate)
        // Note: Do NOT use query.sortDescriptors here, because CloudKit throws an error
        // if 'creationDate' is not configured with a SORTABLE index in the CloudKit Console.
        // We sort in-memory below instead.
        
        let (results, _) = try await publicDB.records(matching: query, desiredKeys: nil, resultsLimit: 200)
        
        var reports: [DogReport] = []
        for (_, result) in results {
            if let record = try? result.get(),
               let report = DogReport(from: record) {
                reports.append(report)
            }
        }
        // In-memory sort by creationDate descending
        reports.sort { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) }
        print("[CloudKit] Successfully fetched \(reports.count) active reports from public database")
        return reports
    }
    
    /// Saves a new dog report to the public database, uploading photos as CKAssets.
    /// Returns the updated report with its CloudKit record name filled in.
    @discardableResult
    func saveReport(_ report: DogReport) async throws -> DogReport {
        let record = CKRecord(recordType: PawRecordType.dogReport)
        
        record[CKReportField.title]          = report.title as CKRecordValue
        record[CKReportField.reporterName]   = report.reporterName as CKRecordValue
        record[CKReportField.reporterUserID] = (report.reporterUserID ?? "") as CKRecordValue
        record[CKReportField.timeReported]   = report.timeReported as CKRecordValue
        record[CKReportField.dateFormatted]  = report.dateFormatted as CKRecordValue
        record[CKReportField.location]       = report.location as CKRecordValue
        record[CKReportField.distance]       = report.distance as CKRecordValue
        // Store lat/lon as NSNumber to satisfy CKRecordValue protocol
        record[CKReportField.latitude]       = NSNumber(value: report.coordinate.latitude)
        record[CKReportField.longitude]      = NSNumber(value: report.coordinate.longitude)
        record[CKReportField.urgencyRaw]     = report.urgency.rawValue as CKRecordValue
        record[CKReportField.description]    = report.description as CKRecordValue
        record[CKReportField.isCompleted]    = NSNumber(value: report.isCompleted ? 1 : 0)
        
        // Encode symptoms as JSON string
        if let symptomsData = try? JSONEncoder().encode(report.symptoms),
           let symptomsJSON = String(data: symptomsData, encoding: .utf8) {
            record[CKReportField.symptomsJSON] = symptomsJSON as CKRecordValue
        }
        
        // Upload photos as CKAssets & attach instant thumbnail
        let assets = photoAssets(from: report.photos)
        if !assets.isEmpty {
            record[CKReportField.photos] = assets as CKRecordValue
        }
        if let primary = report.photos.first ?? report.customImage {
            let thumb = resizeImageIfNeeded(primary, maxDimension: 320)
            if let thumbData = thumb.jpegData(compressionQuality: 0.6) {
                record[CKReportField.thumbnailData] = thumbData as CKRecordValue
            }
        }
        
        print("[CloudKit] Saving DogReport to public database...")
        let savedRecord = try await publicDB.save(record)
        print("[CloudKit] Successfully saved DogReport with recordName: \(savedRecord.recordID.recordName)")
        
        // Cache the uploaded photos locally so they render instantly
        for (i, image) in report.photos.enumerated() {
            let cacheKey = "\(savedRecord.recordID.recordName)_photo_\(i)"
            ImageCacheManager.shared.store(image, forKey: cacheKey)
        }
        
        var updatedReport = report
        updatedReport.cloudKitRecordName = savedRecord.recordID.recordName
        updatedReport.creationDate = savedRecord.creationDate ?? Date()
        return updatedReport
    }
    
    /// Marks an existing report as completed in the public database.
    func markReportCompleted(recordName: String, rescuerUserID: String? = nil, rescuerName: String? = nil) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        let record   = try await publicDB.record(for: recordID)
        record[CKReportField.isCompleted] = NSNumber(value: 1)
        if let rescuerUserID = rescuerUserID, !rescuerUserID.isEmpty {
            record[CKReportField.rescuerUserID] = rescuerUserID as CKRecordValue
        }
        if let rescuerName = rescuerName, !rescuerName.isEmpty {
            record[CKReportField.rescuerName] = rescuerName as CKRecordValue
        }
        _ = try await publicDB.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys)
        print("[CloudKit] Successfully marked report \(recordName) completed on public database")
    }
    
    /// Writes the rescuer's name and userID to an existing report record.
    /// Called when a user taps "Help this dog" — visible to the reporter and all viewers.
    func acceptCase(recordName: String, rescuerUserID: String, rescuerName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        let record   = try await publicDB.record(for: recordID)
        record[CKReportField.rescuerUserID] = rescuerUserID as CKRecordValue
        record[CKReportField.rescuerName]   = rescuerName   as CKRecordValue
        _ = try await publicDB.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys)
        print("[CloudKit] Successfully accepted case \(recordName) with rescuer \(rescuerName)")
    }
    
    /// Clears rescuer info from the report record in the public database.
    /// Called when a rescuer clicks "Can't help" — re-opens the case for everyone and turns pin back to original urgency color.
    func unacceptCase(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        let record   = try await publicDB.record(for: recordID)
        record[CKReportField.rescuerUserID] = "" as CKRecordValue
        record[CKReportField.rescuerName]   = "" as CKRecordValue
        _ = try await publicDB.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys)
        print("[CloudKit] Successfully unaccepted case \(recordName) on public database")
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Feed Posts (Public DB)
    // MARK: - ─────────────────────────────────────────
    
    /// Fetches the latest feed posts (max 100), sorted newest first.
    func fetchFeedPosts() async throws -> [FeedPost] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PawRecordType.feedPost, predicate: predicate)
        
        let (results, _) = try await publicDB.records(matching: query, desiredKeys: nil, resultsLimit: 100)
        
        var posts: [FeedPost] = []
        for (_, result) in results {
            if let record = try? result.get(),
               let post = FeedPost(from: record) {
                posts.append(post)
            }
        }
        // In-memory sort by newest first
        posts.sort { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) }
        print("[CloudKit] Successfully fetched \(posts.count) feed posts from public database")
        return posts
    }
    
    /// Saves a new feed post to the public database, uploading images as CKAssets.
    @discardableResult
    func saveFeedPost(_ post: FeedPost) async throws -> FeedPost {
        let record = CKRecord(recordType: PawRecordType.feedPost)
        
        record[CKFeedField.username]         = post.username as CKRecordValue
        record[CKFeedField.userID]           = (post.userID ?? "") as CKRecordValue
        record[CKFeedField.helperUserID]     = (post.helperUserID ?? post.userID ?? "") as CKRecordValue
        record[CKFeedField.helperUsername]   = (post.helperUsername ?? post.username) as CKRecordValue
        record[CKFeedField.reporterUserID]   = (post.reporterUserID ?? "") as CKRecordValue
        record[CKFeedField.reporterUsername] = (post.reporterUsername ?? "") as CKRecordValue
        record[CKFeedField.caption]          = post.caption as CKRecordValue
        record[CKFeedField.likeCount]        = NSNumber(value: post.likeCount)
        record[CKFeedField.timeAgo]          = post.timeAgo as CKRecordValue
        record[CKFeedField.createdAt]        = Date() as CKRecordValue
        
        // Upload images as CKAssets & attach instant thumbnail
        let allImages = post.images.isEmpty ? (post.dogImage != nil ? [post.dogImage!] : []) : post.images
        let assets = photoAssets(from: allImages)
        if !assets.isEmpty {
            record[CKFeedField.images] = assets as CKRecordValue
        }
        if let primary = allImages.first {
            let thumb = resizeImageIfNeeded(primary, maxDimension: 320)
            if let thumbData = thumb.jpegData(compressionQuality: 0.6) {
                record[CKFeedField.thumbnailData] = thumbData as CKRecordValue
            }
        }
        
        print("[CloudKit] Saving FeedPost to public database: \(post.caption)")
        let savedRecord = try await publicDB.save(record)
        print("[CloudKit] Successfully saved FeedPost with recordName: \(savedRecord.recordID.recordName)")
        
        // Cache images locally
        for (i, image) in allImages.enumerated() {
            let cacheKey = "\(savedRecord.recordID.recordName)_img_\(i)"
            ImageCacheManager.shared.store(image, forKey: cacheKey)
        }
        
        var updatedPost = post
        updatedPost.cloudKitRecordName = savedRecord.recordID.recordName
        updatedPost.creationDate = savedRecord.creationDate ?? Date()
        return updatedPost
    }
    
    /// Atomically toggles a like for the current user on a feed post.
    /// Returns the new like count.
    @discardableResult
    func toggleLike(postRecordName: String, userID: String, currentlyLiked: Bool) async throws -> Int {
        let recordID = CKRecord.ID(recordName: postRecordName)
        let record   = try await publicDB.record(for: recordID)
        
        var likedBy = (record[CKFeedField.likedByUsers] as? [String]) ?? []
        // CloudKit returns integers as NSNumber
        var count   = (record[CKFeedField.likeCount] as? NSNumber)?.intValue ?? 0
        
        if currentlyLiked {
            likedBy.removeAll { $0 == userID }
            count = max(0, count - 1)
        } else {
            if !likedBy.contains(userID) { likedBy.append(userID) }
            count += 1
        }
        
        record[CKFeedField.likedByUsers] = likedBy as CKRecordValue
        record[CKFeedField.likeCount]    = NSNumber(value: count)
        _ = try await publicDB.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys)
        return count
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - User Stats (Private DB)
    // MARK: - ─────────────────────────────────────────
    
    /// Fetches the user's private stats and profile record. Creates one if it doesn't exist yet.
    func fetchUserStats(userID: String) async throws -> (saved: Int, reported: Int, assignedCaseIDs: [String], userName: String?, userEmail: String?, userRole: String?) {
        let predicate = NSPredicate(format: "%K == %@", CKStatsField.userID, userID)
        let query = CKQuery(recordType: PawRecordType.userStats, predicate: predicate)
        
        let (results, _) = try await privateDB.records(matching: query, desiredKeys: nil, resultsLimit: 1)
        
        if let (_, result) = results.first, let record = try? result.get() {
            let saved    = (record[CKStatsField.dogsSaved]       as? NSNumber)?.intValue ?? 0
            let reported = (record[CKStatsField.dogsReported]    as? NSNumber)?.intValue ?? 0
            let caseIDs  = (record[CKStatsField.assignedCaseIDs] as? [String]) ?? []
            let name     = record[CKStatsField.userName] as? String
            let email    = record[CKStatsField.userEmail] as? String
            let role     = record[CKStatsField.userRole] as? String
            return (saved, reported, caseIDs, name, email, role)
        }
        
        // First time — create the stats record
        let newRecord = CKRecord(recordType: PawRecordType.userStats)
        newRecord[CKStatsField.userID]          = userID as CKRecordValue
        newRecord[CKStatsField.dogsSaved]       = NSNumber(value: 0)
        newRecord[CKStatsField.dogsReported]    = NSNumber(value: 0)
        newRecord[CKStatsField.assignedCaseIDs] = [] as CKRecordValue
        try await privateDB.save(newRecord)
        return (0, 0, [], nil, nil, nil)
    }
    
    /// Saves updated user stats and profile back to the private database.
    func saveUserStats(
        userID: String,
        saved: Int,
        reported: Int,
        assignedCaseIDs: [String],
        userName: String? = nil,
        userEmail: String? = nil,
        userRole: String? = nil
    ) async throws {
        let predicate = NSPredicate(format: "%K == %@", CKStatsField.userID, userID)
        let query = CKQuery(recordType: PawRecordType.userStats, predicate: predicate)
        
        let (results, _) = try await privateDB.records(matching: query, desiredKeys: nil, resultsLimit: 1)
        
        let record: CKRecord
        if let (_, result) = results.first, let existing = try? result.get() {
            record = existing
        } else {
            record = CKRecord(recordType: PawRecordType.userStats)
            record[CKStatsField.userID] = userID as CKRecordValue
        }
        
        record[CKStatsField.dogsSaved]       = NSNumber(value: saved)
        record[CKStatsField.dogsReported]    = NSNumber(value: reported)
        record[CKStatsField.assignedCaseIDs] = assignedCaseIDs as CKRecordValue
        if let userName = userName, !userName.isEmpty {
            record[CKStatsField.userName] = userName as CKRecordValue
        }
        if let userEmail = userEmail, !userEmail.isEmpty {
            record[CKStatsField.userEmail] = userEmail as CKRecordValue
        }
        if let userRole = userRole, !userRole.isEmpty {
            record[CKStatsField.userRole] = userRole as CKRecordValue
        }
        _ = try await privateDB.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys)
    }
    
    /// Attempts to discover the user's iCloud user identity name (e.g. "Aryan Kahate")
    func fetchICloudUserName() async -> String? {
        do {
            let recordID = try await container.userRecordID()
            let identity = try await container.userIdentity(forUserRecordID: recordID)
            if let components = identity?.nameComponents {
                let formatter = PersonNameComponentsFormatter()
                let name = formatter.string(from: components)
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        } catch {
            print("[CloudKit] Could not fetch iCloud user identity: \(error.localizedDescription)")
        }
        return nil
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Image Fetching & Optimization
    // MARK: - ─────────────────────────────────────────
    
    /// Loads a photo from a CKRecord's asset field, using disk cache to avoid re-downloading.
    func loadPhoto(from asset: CKAsset, cacheKey: String) -> UIImage? {
        if let cached = ImageCacheManager.shared.cachedImage(forKey: cacheKey) { return cached }
        guard let fileURL = asset.fileURL else { return nil }
        return ImageCacheManager.shared.loadAndCache(from: fileURL, key: cacheKey)
    }
    
    /// Resolves all photo assets from a DogReport CKRecord into UIImages, using cache.
    func resolvePhotos(from record: CKRecord) -> [UIImage] {
        let assets = record[CKReportField.photos] as? [CKAsset] ?? []
        let name   = record.recordID.recordName
        return assets.enumerated().compactMap { (i, asset) in
            loadPhoto(from: asset, cacheKey: "\(name)_photo_\(i)")
        }
    }
    
    /// Resolves all image assets from a FeedPost CKRecord into UIImages, using cache.
    func resolveImages(from record: CKRecord) -> [UIImage] {
        let assets = record[CKFeedField.images] as? [CKAsset] ?? []
        let name   = record.recordID.recordName
        return assets.enumerated().compactMap { (i, asset) in
            loadPhoto(from: asset, cacheKey: "\(name)_img_\(i)")
        }
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Helpers
    // MARK: - ─────────────────────────────────────────
    
    /// Converts an array of UIImages into fast, compressed temp-file-backed CKAssets for upload (max 1200px, 0.65 quality).
    private func photoAssets(from images: [UIImage]) -> [CKAsset] {
        images.enumerated().compactMap { (i, image) -> CKAsset? in
            let resized = resizeImageIfNeeded(image, maxDimension: 1200)
            guard let data = resized.jpegData(compressionQuality: 0.65) else { return nil }
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("ckupload_\(UUID().uuidString)_\(i).jpg")
            try? data.write(to: tempURL)
            return CKAsset(fileURL: tempURL)
        }
    }
    
    /// Resizes large camera photos so uploads and downloads are lightning fast (<150KB per photo)
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        
        let ratio = maxDimension / maxSide
        let targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Database Wipe / Reset All Data
    // MARK: - ─────────────────────────────────────────
    
    /// Deletes all dog report records from the CloudKit public database.
    func deleteAllReportsFromCloud() async {
        do {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: PawRecordType.dogReport, predicate: predicate)
            let (results, _) = try await publicDB.records(matching: query, desiredKeys: nil, resultsLimit: 500)
            for (recordID, _) in results {
                try? await publicDB.deleteRecord(withID: recordID)
            }
            print("[CloudKit] Deleted \(results.count) dog reports from public database")
        } catch {
            print("[CloudKit] Failed to delete dog reports: \(error)")
        }
    }
    
    /// Deletes all feed post records from the CloudKit public database.
    func deleteAllFeedPostsFromCloud() async {
        do {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: PawRecordType.feedPost, predicate: predicate)
            let (results, _) = try await publicDB.records(matching: query, desiredKeys: nil, resultsLimit: 500)
            for (recordID, _) in results {
                try? await publicDB.deleteRecord(withID: recordID)
            }
            print("[CloudKit] Deleted \(results.count) feed posts from public database")
        } catch {
            print("[CloudKit] Failed to delete feed posts: \(error)")
        }
    }
    
    /// Resets user stats record in private database.
    func resetUserStatsInCloud(userID: String) async {
        do {
            try await saveUserStats(userID: userID, saved: 0, reported: 0, assignedCaseIDs: [])
        } catch {
            print("[CloudKit] Failed to reset user stats: \(error)")
        }
    }
}

