import SwiftUI

/// Custom map teardrop marker with white border, hollow paw print, and anchor dot.
struct DogAnnotationView: View {
    let urgency: UrgencyLevel
    var isAccepted: Bool = false
    var isSelected: Bool = false
    @State private var isPulsing = false
    
    // Effective pin color: Blue if accepted, Red for emergency, Yellow for medium, Green for low
    private var effectiveColor: Color {
        if isAccepted {
            return Color(hex: "5C7CFA")
        }
        switch urgency {
        case .emergency, .rabiesRisk, .high:
            return Color(hex: "E53935")
        case .medium:
            return Color(hex: "FBC02D")
        case .low:
            return Color(hex: "2E7D32")
        }
    }
    
    // ONLY unaccepted Red Emergency pins pulse/blink
    private var shouldPulse: Bool {
        !isAccepted && urgency.isUrgentPulsing
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Emergency High-Visibility Pulsing Glow (Fast & Darker Aura)
                if shouldPulse {
                    // Outer expanding aura
                    Circle()
                        .fill(effectiveColor.opacity(isPulsing ? 0.65 : 0.08))
                        .frame(width: 52, height: 52)
                        .scaleEffect(isPulsing ? 1.4 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.55)
                            .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                    
                    // Inner bright warning ring
                    Circle()
                        .fill(effectiveColor.opacity(isPulsing ? 0.85 : 0.18))
                        .frame(width: 40, height: 40)
                        .scaleEffect(isPulsing ? 1.2 : 0.9)
                        .animation(
                            .easeInOut(duration: 0.55)
                            .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }
                
                // Teardrop Marker
                ZStack {
                    // Drop Shadow & Body
                    TeardropPinShape()
                        .fill(effectiveColor)
                        .frame(width: 32, height: 38)
                        .overlay(
                            TeardropPinShape()
                                .stroke(Color.white, lineWidth: 2.2)
                        )
                        .shadow(
                            color: shouldPulse
                                ? Color.black.opacity(isPulsing ? 0.55 : 0.25)
                                : Color.black.opacity(0.2),
                            radius: shouldPulse ? (isPulsing ? 6 : 2.5) : 3,
                            x: 0,
                            y: 2
                        )
                        .shadow(
                            color: effectiveColor.opacity(shouldPulse ? (isPulsing ? 0.95 : 0.4) : 0.4),
                            radius: shouldPulse ? (isPulsing ? 10 : 3.5) : 4,
                            x: 0,
                            y: shouldPulse ? (isPulsing ? 3 : 1) : 2
                        )
                    
                    // White Hollow/Outline Paw Print Icon in upper circle
                    Image(systemName: "pawprint")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: -4)
                }
                .scaleEffect(shouldPulse ? (isPulsing ? 1.07 : 0.95) : 1.0)
                .animation(
                    shouldPulse ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true) : .default,
                    value: isPulsing
                )
            }
            
            // Anchor Base Dot below the tip
            Circle()
                .fill(Color.white)
                .frame(width: 4.5, height: 4.5)
                .overlay(
                    Circle().stroke(Color.gray.opacity(0.4), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 1.5, x: 0, y: 1)
        }
        .scaleEffect(isSelected ? 1.22 : 1.0)
        .offset(y: isSelected ? -4 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
        .onAppear {
            if shouldPulse {
                withAnimation {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
        .onChange(of: isAccepted) { _, newValue in
            if !newValue && urgency.isUrgentPulsing {
                withAnimation {
                    isPulsing = true
                }
            } else {
                withAnimation {
                    isPulsing = false
                }
            }
        }
    }
}

// MARK: - Teardrop Pin Shape
struct TeardropPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let radius = width / 2
        let center = CGPoint(x: rect.midX, y: rect.minY + radius)
        
        // Arc around top circle
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(145),
            endAngle: .degrees(35),
            clockwise: false
        )
        // Straight lines converging to bottom tip
        path.addLine(to: CGPoint(x: rect.midX, y: height))
        path.closeSubpath()
        return path
    }
}

#Preview {
    HStack(spacing: 20) {
        DogAnnotationView(urgency: .low)
        DogAnnotationView(urgency: .medium)
        DogAnnotationView(urgency: .emergency)
        DogAnnotationView(urgency: .high, isAccepted: true)
    }
    .padding(40)
    .background(Color.gray.opacity(0.15))
}
