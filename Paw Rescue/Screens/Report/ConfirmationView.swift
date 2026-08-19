import SwiftUI

/// Confirmation screen after report submission.
struct ConfirmationView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isReportFlowPresented: Bool
    @State private var showCheckmark = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            AppColors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: AppConstants.spacingXXL) {
                Spacer()
                
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(AppColors.primaryBlue.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0)
                    
                    Circle()
                        .fill(AppColors.primaryBlue)
                        .frame(width: 80, height: 80)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppColors.white)
                        .scaleEffect(showCheckmark ? 1.0 : 0.3)
                        .opacity(showCheckmark ? 1.0 : 0)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCheckmark)
                
                VStack(spacing: AppConstants.spacingM) {
                    Text("Report Submitted")
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.black)
                    
                    Text("Thank you for helping. Your report has been filed and nearby rescuers will be notified.")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.gray500)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppConstants.spacingXXXL)
                }
                .opacity(showText ? 1.0 : 0)
                .offset(y: showText ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showText)
                
                Spacer()
                
                // Back to Map button
                Button {
                    isReportFlowPresented = false
                } label: {
                    Text("Back to Map")
                        .font(AppFonts.button())
                        .foregroundColor(AppColors.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppConstants.buttonHeight)
                        .background(AppColors.primaryBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, AppConstants.horizontalPadding)
                .padding(.bottom, AppConstants.spacingHuge)
                .opacity(showText ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: showText)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showCheckmark = true
                showText = true
            }
        }
    }
}

#Preview {
    ConfirmationView(isReportFlowPresented: .constant(true))
        .environmentObject(AppState())
}
