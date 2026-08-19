import CoreLocation

/// Static reference data that does NOT require a backend.
/// Dog reports and feed posts are now fully managed by CloudKit — no mock seeding.
enum MockData {
    // MARK: - Default Map Center (Kuta, Bali)
    /// Used as the initial camera position before real GPS is obtained.
    static let kutaCenter = CLLocationCoordinate2D(latitude: -8.7180, longitude: 115.1690)
    
    // MARK: - Nearest Animal Shelters
    /// Static shelter data — displayed on the ReportCreatedView. No backend needed.
    static let nearestShelters: [AnimalShelter] = [
        AnimalShelter(
            name: "Mybalidogrescue",
            status: "Open",
            distanceTime: "2,9 km · 8 min",
            phoneNumber: "+628123456789",
            coordinate: CLLocationCoordinate2D(latitude: -8.7150, longitude: 115.1720)
        ),
        AnimalShelter(
            name: "Bali Animal Welfare",
            status: "Open",
            distanceTime: "4,6 km · 14 min",
            phoneNumber: "+628198765432",
            coordinate: CLLocationCoordinate2D(latitude: -8.7050, longitude: 115.1790)
        )
    ]
}
