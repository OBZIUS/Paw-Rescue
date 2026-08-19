import SwiftUI

/// Instruction screen: "What to do" — 3 clean instruction cards with liquid glass controls.
struct InstructionsView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isPresented: Bool
    @StateObject private var cameraManager = CameraManager()
    @State private var currentStep: ReportFlowStep = .instructions
    
    enum ReportFlowStep {
        case instructions
        case camera
        case review
        case form
    }
    
    var body: some View {
        Group {
            switch currentStep {
            case .instructions:
                instructionsContent
            case .camera:
                CameraView(
                    cameraManager: cameraManager,
                    isReportFlowPresented: $isPresented,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep = .instructions
                        }
                    },
                    onReviewTapped: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep = .review
                        }
                    }
                )
            case .review:
                ReviewPhotosView(
                    cameraManager: cameraManager,
                    isReportFlowPresented: $isPresented,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep = .camera
                        }
                    },
                    onContinueToForm: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep = .form
                        }
                    }
                )
            case .form:
                ReportFormView(
                    cameraManager: cameraManager,
                    isReportFlowPresented: $isPresented,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep = .review
                        }
                    }
                )
            }
        }
    }
    
    private var instructionsContent: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Header with Glass Close Button & Title
                    HStack {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(LiquidGlassCircleButtonStyle(size: 36))
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.top, AppConstants.spacingL)
                    
                    // Title
                    Text("What to do")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.black)
                        .padding(.horizontal, AppConstants.horizontalPadding)
                        .padding(.top, AppConstants.spacingXL)
                    
                    Spacer()
                        .frame(height: 28)
                    
                    // Three instruction cards
                    VStack(spacing: AppConstants.spacingL) {
                        instructionCard(
                            number: 1,
                            title: "Take 1 - 5 photos",
                            description: "One photo is enough, but more are encouraged. Try to capture the dog from different angles."
                        )
                        
                        instructionCard(
                            number: 2,
                            title: "Answer a few simple questions",
                            description: "Tell us what you see as accurately as possible. Your answers help others understand the dog's condition and provide the right help."
                        )
                        
                        instructionCard(
                            number: 3,
                            title: "Submit your report",
                            description: "Review your information and send the report. Every detail can help."
                        )
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    
                    Spacer()
                    
                    // Continue to camera button
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep = .camera
                        }
                    } label: {
                        Text("Continue to camera")
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
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Instruction Card
    @ViewBuilder
    private func instructionCard(number: Int, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(AppColors.black)
            
            Text(description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppColors.gray600)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL)
                .fill(AppColors.secondaryCream.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    InstructionsView(isPresented: .constant(true))
        .environmentObject(AppState())
}
