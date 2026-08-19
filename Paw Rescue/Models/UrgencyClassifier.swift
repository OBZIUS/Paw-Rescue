import SwiftUI

/// Priority Urgency Levels decided by the triage algorithm
enum UrgencyLevel: String, CaseIterable, Codable {
    case rabiesRisk = "Rabies Risk"
    case emergency = "Emergency"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .rabiesRisk, .emergency:
            return AppColors.pinRed
        case .high:
            return Color(hex: "FF6B4A")
        case .medium:
            return AppColors.pinYellow
        case .low:
            return AppColors.pinGreen
        }
    }
    
    var isUrgentPulsing: Bool {
        return self == .rabiesRisk || self == .emergency || self == .high
    }
    
    var description: String {
        switch self {
        case .rabiesRisk:
            return "Rabies risk detected. The dog exhibits biting or foaming symptoms. Extreme caution is advised."
        case .emergency:
            return "Critical condition. The dog cannot move or is severely injured. Immediate medical rescue needed."
        case .high:
            return "High priority report. Visible open bleeding or trapped condition requires urgent responder intervention."
        case .medium:
            return "Moderate condition. The dog has visible wounds or struggle but is stable."
        case .low:
            return "Low urgency report. The dog is mobile and stable, but requires attention and monitoring."
        }
    }
}

enum UrgencyClassifier {
    static func classify(
        hasBittenOrRabies: String?,
        woundStatus: String?,
        mobilityStatus: String?
    ) -> UrgencyLevel {
        // Q1: Rabies / Bite
        if hasBittenOrRabies?.lowercased() == "yes" {
            return .rabiesRisk
        }
        
        let wound = woundStatus ?? ""
        let mobility = mobilityStatus ?? ""
        
        // Q2: Wound & Bleeding
        if wound.contains("bleeding") && !wound.contains("not bleeding") && !wound.contains("no wound") {
            if mobility.contains("Can't move") {
                return .emergency
            } else {
                return .high
            }
        }
        
        // Q2: Wound, No bleeding
        if wound.contains("not bleeding") {
            if mobility.contains("Can't move") {
                return .emergency
            } else if mobility.contains("Stuck") || mobility.contains("trapped") {
                return .high
            } else {
                return .medium
            }
        }
        
        // Q2: No wound, No bleed
        if mobility.contains("Can't move") {
            return .emergency
        } else if mobility.contains("Stuck") || mobility.contains("Struggles") {
            return .medium
        } else {
            return .low
        }
    }
}
