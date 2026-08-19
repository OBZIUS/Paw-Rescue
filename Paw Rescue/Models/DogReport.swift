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
        isCompleted: Bool = false
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
    }
    
    // MARK: - CloudKit Deserialization
    
    /// Initialises a DogReport from a CloudKit CKRecord.
    /// Photos are loaded asynchronously via CloudKitManager.resolvePhotos(from:).
    init?(from record: CKRecord) {
        // CloudKit returns numbers as NSNumber — extract .doubleValue safely
        guard
            let title         = record[CKReportField.title]        as? String,
            let reporterName  = record[CKReportField.reporterName]  as? String,
            let location      = record[CKReportField.location]      as? String,
            let latNum        = record[CKReportField.latitude]      as? NSNumber,
            let lonNum        = record[CKReportField.longitude]     as? NSNumber,
            let urgencyRaw    = record[CKReportField.urgencyRaw]    as? String,
            let urgency       = UrgencyLevel(rawValue: urgencyRaw),
            let description   = record[CKReportField.description]   as? String
        else { return nil }
        let latitude  = latNum.doubleValue
        let longitude = lonNum.doubleValue
        
        self.id                  = UUID()
        self.cloudKitRecordName  = record.recordID.recordName
        self.reporterUserID      = record[CKReportField.reporterUserID] as? String
        self.rescuerUserID       = record[CKReportField.rescuerUserID]  as? String
        self.rescuerName         = record[CKReportField.rescuerName]    as? String
        self.title               = title
        self.reporterName        = reporterName
        self.reporterAvatarName  = "person.circle.fill"
        self.timeReported        = record[CKReportField.timeReported]   as? String ?? "Recently"
        self.dateFormatted       = record[CKReportField.dateFormatted]  as? String ?? ""
        self.location            = location
        self.distance            = record[CKReportField.distance]       as? String ?? ""
        self.coordinate          = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.urgency             = urgency
        self.description         = description
        self.isCompleted         = (record[CKReportField.isCompleted] as? NSNumber)?.intValue == 1
        self.isAssignedToUser    = false
        self.imageName           = nil
        
        // Decode symptoms from JSON
        if let symptomsJSON = record[CKReportField.symptomsJSON] as? String,
           let data = symptomsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Symptom].self, from: data) {
            self.symptoms = decoded
        } else {
            self.symptoms = [Symptom(name: "Needs Care", iconName: "heart.fill")]
        }
        
        // Load cached photos synchronously (assets already downloaded by CloudKit)
        let ckm = CloudKitManager.shared
        self.photos      = ckm.resolvePhotos(from: record)
        self.customImage = self.photos.first
    }
}

// MARK: - Feed Post
struct FeedPost: Identifiable {
    let id: UUID
    var cloudKitRecordName: String?   // CloudKit record name for like syncing
    var userID: String?               // Apple ID of poster
    var username: String
    var userAvatarName: String
    var dogImage: UIImage?
    var images: [UIImage] = []
    var caption: String
    var likeCount: Int = 0
    var isLiked: Bool = false
    var timeAgo: String = "Today"
    
    init(
        id: UUID = UUID(),
        cloudKitRecordName: String? = nil,
        userID: String? = nil,
        username: String,
        userAvatarName: String = "person.crop.circle.fill",
        dogImage: UIImage? = nil,
        images: [UIImage] = [],
        caption: String,
        likeCount: Int = 1,
        isLiked: Bool = false,
        timeAgo: String = "Just now"
    ) {
        self.id                 = id
        self.cloudKitRecordName = cloudKitRecordName
        self.userID             = userID
        self.username           = username
        self.userAvatarName     = userAvatarName
        self.dogImage           = dogImage ?? images.first
        self.images             = images.isEmpty ? (dogImage != nil ? [dogImage!] : []) : images
        self.caption            = caption
        self.likeCount          = likeCount
        self.isLiked            = isLiked
        self.timeAgo            = timeAgo
    }
    
    // MARK: - CloudKit Deserialization
    
    /// Initialises a FeedPost from a CloudKit CKRecord.
    init?(from record: CKRecord) {
        guard
            let username = record[CKFeedField.username] as? String,
            let caption  = record[CKFeedField.caption]  as? String
        else { return nil }
        
        self.id                 = UUID()
        self.cloudKitRecordName = record.recordID.recordName
        self.userID             = record[CKFeedField.userID]    as? String
        self.username           = username
        self.userAvatarName     = "person.crop.circle.fill"
        self.caption            = caption
        self.likeCount          = (record[CKFeedField.likeCount] as? NSNumber)?.intValue ?? 0
        self.isLiked            = false  // resolved per-user in AppState
        self.timeAgo            = Self.relativeTime(from: record.creationDate)
        
        // Load cached images synchronously
        let ckm  = CloudKitManager.shared
        let imgs = ckm.resolveImages(from: record)
        self.images   = imgs
        self.dogImage = imgs.first
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
    
    var calculatedUrgency: UrgencyLevel {
        UrgencyClassifier.classify(
            hasBittenOrRabies: hasBittenOrRabiesSymptoms,
            woundStatus: woundStatus,
            mobilityStatus: mobilityStatus
        )
    }
}
