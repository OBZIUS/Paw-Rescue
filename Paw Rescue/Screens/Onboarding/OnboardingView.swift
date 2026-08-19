import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack {
            AppColors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: AppConstants.spacingXXL)
                
                // Video area
                OnboardingVideoPlayer()
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .allowsHitTesting(false)
                
                Spacer()
                    .frame(height: AppConstants.spacingXXL)
                
                // Heading - Centered alignment
                VStack(alignment: .center, spacing: AppConstants.spacingM) {
                    Text("Every street dog\ndeserves a rescuer.")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.black)
                        .multilineTextAlignment(.center)
                    
                    Text("Report an injured dog in seconds. Someone nearby gets there before it's too late.")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.gray500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppConstants.horizontalPadding).padding(.top,45)
                
                Spacer()
                
                // Get Started button
                Button(action: {
                    appState.completeOnboarding()
                }) {
                    Text("Get started")
                        .font(AppFonts.button())
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppConstants.buttonHeight)
                        .background(AppColors.primaryBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppConstants.horizontalPadding + 24)
                .padding(.bottom, AppConstants.spacingHuge)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
