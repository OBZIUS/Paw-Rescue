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
    static let isCompleted    = "isCompleted"
}

enum CKFeedField {
    static let username       = "username"
    static let userID         = "userID"
    static let caption        = "caption"
    static let likeCount      = "likeCount"
    static let likedByUsers   = "likedByUsers"  // [String] user IDs
    static let images         = "images"        // [CKAsset]
    static let timeAgo        = "timeAgo"
    static let createdAt      = "createdAt"
}

enum CKStatsField {
    static let userID          = "userID"
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
        container = CKContainer(identifier: "iCloud.com.pawrescue.app")
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Dog Reports (Public DB)
    // MARK: - ─────────────────────────────────────────
    
    /// Fetches all dog reports from the public database, sorted newest first.
    func fetchReports() async throws -> [DogReport] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PawRecordType.dogReport, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let (results, _) = try await publicDB.records(matching: query, desiredKeys: nil, resultsLimit: 200)
        
        var reports: [DogReport] = []
        for (_, result) in results {
            if let record = try? result.get(),
               let report = DogReport(from: record) {
                reports.append(report)
            }
        }
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
        
        // Upload photos as CKAssets
        let assets = photoAssets(from: report.photos)
        if !assets.isEmpty {
            record[CKReportField.photos] = assets as CKRecordValue
        }
        
        let savedRecord = try await publicDB.save(record)
        
        // Cache the uploaded photos locally so they render instantly
        for (i, image) in report.photos.enumerated() {
            let cacheKey = "\(savedRecord.recordID.recordName)_photo_\(i)"
            ImageCacheManager.shared.store(image, forKey: cacheKey)
        }
        
        var updatedReport = report
        updatedReport.cloudKitRecordName = savedRecord.recordID.recordName
        return updatedReport
    }
    
    /// Marks an existing report as completed in the public database.
    func markReportCompleted(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        let record   = try await publicDB.record(for: recordID)
        record[CKReportField.isCompleted] = NSNumber(value: 1)
        try await publicDB.save(record)
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Feed Posts (Public DB)
    // MARK: - ─────────────────────────────────────────
    
    /// Fetches the latest feed posts (max 100), sorted newest first.
    func fetchFeedPosts() async throws -> [FeedPost] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PawRecordType.feedPost, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let (results, _) = try await publicDB.records(matching: query, desiredKeys: nil, resultsLimit: 100)
        
        var posts: [FeedPost] = []
        for (_, result) in results {
            if let record = try? result.get(),
               let post = FeedPost(from: record) {
                posts.append(post)
            }
        }
        return posts
    }
    
    /// Saves a new feed post to the public database, uploading images as CKAssets.
    @discardableResult
    func saveFeedPost(_ post: FeedPost) async throws -> FeedPost {
        let record = CKRecord(recordType: PawRecordType.feedPost)
        
        record[CKFeedField.username]      = post.username as CKRecordValue
        record[CKFeedField.userID]        = (post.userID ?? "") as CKRecordValue
        record[CKFeedField.caption]       = post.caption as CKRecordValue
        record[CKFeedField.likeCount]     = NSNumber(value: post.likeCount)
        record[CKFeedField.timeAgo]       = post.timeAgo as CKRecordValue
        record[CKFeedField.createdAt]     = Date() as CKRecordValue
        record[CKFeedField.likedByUsers]  = [] as CKRecordValue
        
        // Upload images as CKAssets
        let assets = photoAssets(from: post.images)
        if !assets.isEmpty {
            record[CKFeedField.images] = assets as CKRecordValue
        }
        
        let savedRecord = try await publicDB.save(record)
        
        // Cache images locally
        for (i, image) in post.images.enumerated() {
            let cacheKey = "\(savedRecord.recordID.recordName)_img_\(i)"
            ImageCacheManager.shared.store(image, forKey: cacheKey)
        }
        
        var updatedPost = post
        updatedPost.cloudKitRecordName = savedRecord.recordID.recordName
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
        try await publicDB.save(record)
        return count
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - User Stats (Private DB)
    // MARK: - ─────────────────────────────────────────
    
    /// Fetches the user's private stats record. Creates one if it doesn't exist yet.
    func fetchUserStats(userID: String) async throws -> (saved: Int, reported: Int, assignedCaseIDs: [String]) {
        let predicate = NSPredicate(format: "%K == %@", CKStatsField.userID, userID)
        let query = CKQuery(recordType: PawRecordType.userStats, predicate: predicate)
        
        let (results, _) = try await privateDB.records(matching: query, desiredKeys: nil, resultsLimit: 1)
        
        if let (_, result) = results.first, let record = try? result.get() {
            let saved    = (record[CKStatsField.dogsSaved]       as? NSNumber)?.intValue ?? 0
            let reported = (record[CKStatsField.dogsReported]    as? NSNumber)?.intValue ?? 0
            let caseIDs  = (record[CKStatsField.assignedCaseIDs] as? [String]) ?? []
            return (saved, reported, caseIDs)
        }
        
        // First time — create the stats record
        let newRecord = CKRecord(recordType: PawRecordType.userStats)
        newRecord[CKStatsField.userID]          = userID as CKRecordValue
        newRecord[CKStatsField.dogsSaved]       = NSNumber(value: 0)
        newRecord[CKStatsField.dogsReported]    = NSNumber(value: 0)
        newRecord[CKStatsField.assignedCaseIDs] = [] as CKRecordValue
        try await privateDB.save(newRecord)
        return (0, 0, [])
    }
    
    /// Saves updated user stats back to the private database.
    func saveUserStats(userID: String, saved: Int, reported: Int, assignedCaseIDs: [String]) async throws {
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
        try await privateDB.save(record)
    }
    
    // MARK: - ─────────────────────────────────────────
    // MARK: - Image Fetching
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
    
    /// Converts an array of UIImages into temp-file-backed CKAssets for upload.
    private func photoAssets(from images: [UIImage]) -> [CKAsset] {
        images.enumerated().compactMap { (i, image) -> CKAsset? in
            guard let data = image.jpegData(compressionQuality: 0.75) else { return nil }
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("ckupload_\(UUID().uuidString)_\(i).jpg")
            try? data.write(to: tempURL)
            return CKAsset(fileURL: tempURL)
        }
    }
}
