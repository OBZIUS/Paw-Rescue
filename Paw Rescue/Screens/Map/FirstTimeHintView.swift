import SwiftUI

/// First-time instructional hint pointing to the siren button.
struct FirstTimeHintView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: AppConstants.spacingS) {
            Text("Tap here to report")
                .font(AppFonts.footnoteMedium())
                .foregroundColor(AppColors.black)
            
            // Arrow pointing right toward the button
            Image(systemName: "arrowtriangle.right.fill")
                .font(.system(size: 10))
                .foregroundColor(AppColors.gray400)
        }
        .padding(.horizontal, AppConstants.spacingL)
        .padding(.vertical, AppConstants.spacingM)
        .background(
            AppColors.white
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusMedium))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .onTapGesture {
            onDismiss()
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        FirstTimeHintView { }
    }
}
