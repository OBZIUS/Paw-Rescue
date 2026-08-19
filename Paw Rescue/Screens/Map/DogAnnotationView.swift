import SwiftUI

/// Custom map annotation view with Apple-native pulsing urgency glow for emergency pins.
struct DogAnnotationView: View {
    let urgency: UrgencyLevel
    var isSelected: Bool = false
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Urgent Pulsing Glow Rings for Red / Urgent Pins (HIG Native Animation)
                if urgency.isUrgentPulsing {
                    Circle()
                        .fill(urgency.color.opacity(isPulsing ? 0.35 : 0.05))
                        .frame(width: AppConstants.pinSize + 22, height: AppConstants.pinSize + 22)
                        .scaleEffect(isPulsing ? 1.25 : 0.85)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                    
                    Circle()
                        .fill(urgency.color.opacity(isPulsing ? 0.25 : 0.1))
                        .frame(width: AppConstants.pinSize + 12, height: AppConstants.pinSize + 12)
                        .scaleEffect(isPulsing ? 1.15 : 0.95)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true)
                            .delay(0.15),
                            value: isPulsing
                        )
                }
                
                // Main pin marker body
                Circle()
                    .fill(urgency.color)
                    .frame(width: AppConstants.pinSize, height: AppConstants.pinSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2.5)
                    )
                    .shadow(color: urgency.color.opacity(0.4), radius: 6, x: 0, y: 3)
                
                // Paw Icon
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.white)
            }
            
            // Bottom pin pointer tip
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundColor(urgency.color)
                .offset(y: -2)
        }
        .scaleEffect(isSelected ? 1.28 : 1.0)
        .offset(y: isSelected ? -8 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isSelected)
        .onAppear {
            if urgency.isUrgentPulsing {
                isPulsing = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 30) {
        DogAnnotationView(urgency: .low)
        DogAnnotationView(urgency: .medium)
        DogAnnotationView(urgency: .high)
        DogAnnotationView(urgency: .emergency)
    }
    .padding(40)
    .background(Color.gray.opacity(0.2))
}
