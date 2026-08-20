import SwiftUI
import CoreLocation
import CloudKit

// MARK: - Symptom
struct Symptom: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    
    init(id: UUID = UUID(), name: String, iconName: String) {
        self.id = id
        self.name = name
        self.iconName = iconName
    }
}

// MARK: - Animal Shelter
struct AnimalShelter: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let distanceTime: String
    let phoneNumber: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Dog Report
struct DogReport: Identifiable {
    let id: UUID
    var cloudKitRecordName: String?   // CloudKit CKRecord.ID.recordName for updates
    var reporterUserID: String?       // Apple ID user identifier of who reported it
    var rescuerUserID: String?        // Apple ID of whoever accepted the case
    var rescuerName: String?          // Display name of the rescuer (shown to reporter)
    var title: String
    var imageName: String?
    var customImage: UIImage?
    var photos: [UIImage] = []
    var reporterName: String
    var reporterAvatarName: String
    var timeReported: String
    var dateFormatted: String
    var location: String
    var distance: String
    var coordinate: CLLocationCoordinate2D
    var urgency: UrgencyLevel
    var description: String
    var symptoms: [Symptom]
    var isAssignedToUser: Bool = false
    var isCompleted: Bool = false
    var creationDate: Date? = nil
    
    init(
        id: UUID = UUID(),
        cloudKitRecordName: String? = nil,
        reporterUserID: String? = nil,
        rescuerUserID: String? = nil,
        rescuerName: String? = nil,
        title: String = "DOG #1",
        imageName: String? = nil,
        customImage: UIImage? = nil,
        photos: [UIImage] = [],
        reporterName: String,
        reporterAvatarName: String = "person.circle.fill",
        timeReported: String = "Just now",
        dateFormatted: String = "1 August 2026",
        location: String,
        distance: String = "300 m away",
        coordinate: CLLocationCoordinate2D,
        urgency: UrgencyLevel,
        description: String,
        symptoms: [Symptom],
        isAssignedToUser: Bool = false,
        isCompleted: Bool = false,
        creationDate: Date? = nil
    ) {
        self.id = id
        self.cloudKitRecordName = cloudKitRecordName
        self.reporterUserID = reporterUserID
        self.rescuerUserID = rescuerUserID
        self.rescuerName = rescuerName
        self.title = title
        self.imageName = imageName
        self.customImage = customImage ?? photos.first
        self.photos = photos.isEmpty ? (customImage != nil ? [customImage!] : []) : photos
        self.reporterName = reporterName
        self.reporterAvatarName = reporterAvatarName
        self.timeReported = timeReported
        self.dateFormatted = dateFormatted
        self.location = location
        self.distance = distance
        self.coordinate = coordinate
        self.urgency = urgency
        self.description = description
        self.symptoms = symptoms
        self.isAssignedToUser = isAssignedToUser
        self.isCompleted = isCompleted
        self.creationDate = creationDate ?? Date()
    }
    
    // MARK: - CloudKit Deserialization
    
    /// Initialises a DogReport from a CloudKit CKRecord with fail-safe defaults for missing fields.
    init?(from record: CKRecord) {
        // Robust coordinate extraction (handles NSNumber or Double)
        let latitude: Double
        if let latNum = record[CKReportField.latitude] as? NSNumber {
            latitude = latNum.doubleValue
        } else if let latDbl = record[CKReportField.latitude] as? Double {
            latitude = latDbl
        } else {
            return nil
        }
        
        let longitude: Double
        if let lonNum = record[CKReportField.longitude] as? NSNumber {
            longitude = lonNum.doubleValue
        } else if let lonDbl = record[CKReportField.longitude] as? Double {
            longitude = lonDbl
        } else {
            return nil
        }
        
        let titleRaw       = record[CKReportField.title]        as? String ?? "Dog"
        let locationRaw    = record[CKReportField.location]     as? String ?? "Bali"
        let reporterName   = record[CKReportField.reporterName] as? String ?? "Anonymous"
        let urgencyRaw     = record[CKReportField.urgencyRaw]   as? String ?? "Medium"
        let urgency        = UrgencyLevel(rawValue: urgencyRaw) ?? .medium
        let descriptionRaw = record[CKReportField.description]  as? String ?? ""
        
        if let stableUUID = UUID(uuidString: record.recordID.recordName) {
            self.id = stableUUID
        } else {
            let hash = record.recordID.recordName.utf8.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1) }
            self.id = UUID(uuidString: String(format: "%08x-0000-0000-0000-%012x", abs(hash), abs(hash))) ?? UUID()
        }
        self.cloudKitRecordName  = record.recordID.recordName
        let repUID = record[CKReportField.reporterUserID] as? String
        self.reporterUserID      = (repUID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? repUID : nil
        let rescUID = record[CKReportField.rescuerUserID] as? String
        self.rescuerUserID       = (rescUID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? rescUID : nil
        let rescName = record[CKReportField.rescuerName] as? String
        self.rescuerName         = (rescName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? rescName : nil
        self.title               = titleRaw
        self.reporterName        = reporterName
        self.reporterAvatarName  = "person.circle.fill"
        self.timeReported        = record[CKReportField.timeReported]   as? String ?? "Recently"
        self.dateFormatted       = record[CKReportField.dateFormatted]  as? String ?? ""
        self.location            = locationRaw
        self.distance            = record[CKReportField.distance]       as? String ?? ""
        self.coordinate          = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.urgency             = urgency
        self.description         = descriptionRaw
        if let compNum = record[CKReportField.isCompleted] as? NSNumber {
            self.isCompleted = compNum.intValue == 1
        } else if let compInt = record[CKReportField.isCompleted] as? Int {
            self.isCompleted = compInt == 1
        } else if let compBool = record[CKReportField.isCompleted] as? Bool {
            self.isCompleted = compBool
        } else {
            self.isCompleted = false
        }
        self.isAssignedToUser    = false
        self.imageName           = nil
        self.creationDate        = record.creationDate ?? Date()
        
        // Decode symptoms from JSON
        if let symptomsJSON = record[CKReportField.symptomsJSON] as? String,
           let data = symptomsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Symptom].self, from: data) {
            self.symptoms = decoded
        } else {
            self.symptoms = [Symptom(name: "Needs Care", iconName: "heart.fill")]
        }
        
        // Instant thumbnail display
        if let thumbData = record[CKReportField.thumbnailData] as? Data,
           let thumbImage = UIImage(data: thumbData) {
            self.customImage = thumbImage
            self.photos = [thumbImage]
        }
        
        // Load full cached photos
        let ckm = CloudKitManager.shared
        let resolvedPhotos = ckm.resolvePhotos(from: record)
        if !resolvedPhotos.isEmpty {
            self.photos = resolvedPhotos
            self.customImage = resolvedPhotos.first
        }
    }
}

// MARK: - Feed Post
struct FeedPost: Identifiable {
    let id: UUID
    var cloudKitRecordName: String?   // CloudKit record name for like syncing
    var userID: String?               // Apple ID of poster / helper
    var username: String              // Display name of poster / helper
    var userAvatarName: String
    
    // Dual User Tagging (Helper & Original Reporter)
    var helperUserID: String?
    var helperUsername: String?
    var reporterUserID: String?
    var reporterUsername: String?
    
    var dogImage: UIImage?
    var images: [UIImage] = []
    var caption: String
    var likeCount: Int = 0
    var isLiked: Bool = false
    var timeAgo: String = "Today"
    var creationDate: Date? = nil
    
    init(
        id: UUID = UUID(),
        cloudKitRecordName: String? = nil,
        userID: String? = nil,
        username: String,
        userAvatarName: String = "person.crop.circle.fill",
        helperUserID: String? = nil,
        helperUsername: String? = nil,
        reporterUserID: String? = nil,
        reporterUsername: String? = nil,
        dogImage: UIImage? = nil,
        images: [UIImage] = [],
        caption: String,
        likeCount: Int = 1,
        isLiked: Bool = false,
        timeAgo: String = "Just now",
        creationDate: Date? = nil
    ) {
        self.id                 = id
        self.cloudKitRecordName = cloudKitRecordName
        self.userID             = userID
        self.username           = username
        self.userAvatarName     = userAvatarName
        self.helperUserID       = helperUserID ?? userID
        self.helperUsername     = helperUsername ?? username
        self.reporterUserID     = reporterUserID
        self.reporterUsername   = reporterUsername
        self.dogImage           = dogImage ?? images.first
        self.images             = images.isEmpty ? (dogImage != nil ? [dogImage!] : []) : images
        self.caption            = caption
        self.likeCount          = likeCount
        self.isLiked            = isLiked
        self.timeAgo            = timeAgo
        self.creationDate       = creationDate
    }
    
    // MARK: - CloudKit Deserialization
    
    /// Initialises a FeedPost from a CloudKit CKRecord.
    init?(from record: CKRecord) {
        let username = (record[CKFeedField.username] as? String) ?? "community_rescuer"
        let caption  = (record[CKFeedField.caption]  as? String) ?? ""
        let likedBy = (record[CKFeedField.likedByUsers] as? [String]) ?? []
        let currentUID = AuthManager.shared.currentUserID
        
        self.id                 = UUID()
        self.cloudKitRecordName = record.recordID.recordName
        self.userID             = record[CKFeedField.userID]    as? String
        self.username           = username
        self.userAvatarName     = "person.crop.circle.fill"
        self.helperUserID       = (record[CKFeedField.helperUserID] as? String) ?? (record[CKFeedField.userID] as? String)
        self.helperUsername     = (record[CKFeedField.helperUsername] as? String) ?? username
        self.reporterUserID     = record[CKFeedField.reporterUserID] as? String
        self.reporterUsername   = record[CKFeedField.reporterUsername] as? String
        self.caption            = caption
        self.likeCount          = (record[CKFeedField.likeCount] as? NSNumber)?.intValue ?? 0
        self.isLiked            = !currentUID.isEmpty && likedBy.contains(currentUID)
        self.timeAgo            = Self.relativeTime(from: record.creationDate)
        self.creationDate       = record.creationDate
        
        // Instant thumbnail display
        if let thumbData = record[CKFeedField.thumbnailData] as? Data,
           let thumbImage = UIImage(data: thumbData) {
            self.dogImage = thumbImage
            self.images   = [thumbImage]
        }
        
        // Load full cached images
        let ckm  = CloudKitManager.shared
        let imgs = ckm.resolveImages(from: record)
        if !imgs.isEmpty {
            self.images   = imgs
            self.dogImage = imgs.first
        }
    }
    
    // MARK: - Helper
    
    private static func relativeTime(from date: Date?) -> String {
        guard let date = date else { return "Recently" }
        let diff = Date().timeIntervalSince(date)
        if diff < 60            { return "Just now" }
        if diff < 3600          { return "\(Int(diff / 60))m ago" }
        if diff < 86400         { return "\(Int(diff / 3600))h ago" }
        if diff < 86400 * 2     { return "Yesterday" }
        return "\(Int(diff / 86400))d ago"
    }
}

// MARK: - Report Form Data
struct ReportFormData {
    var photos: [UIImage] = []
    var hasBittenOrRabiesSymptoms: String?
    var woundStatus: String?
    var mobilityStatus: String?
    var visualCues: Set<String> = []
    var additionalDescription: String = ""
    var selectedCoordinate: CLLocationCoordinate2D?
    var locationName: String?
    
    var calculatedUrgency: UrgencyLevel {
        UrgencyClassifier.classify(
            hasBittenOrRabies: hasBittenOrRabiesSymptoms,
            woundStatus: woundStatus,
            mobilityStatus: mobilityStatus
        )
    }
}
