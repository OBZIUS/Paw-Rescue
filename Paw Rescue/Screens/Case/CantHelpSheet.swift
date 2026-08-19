import SwiftUI

/// "What happened?" modal sheet when user cannot complete a rescue case.
struct CantHelpSheet: View {
    let reportId: UUID
    @EnvironmentObject private var appState: AppState
    @Binding var isPresented: Bool
    var onCaseUnassigned: () -> Void
    
    @State private var selectedReason: String = "Dog not found"
    @State private var customCaption: String = ""
    
    private let reasons = [
        "Dog not found",
        "Couldn’t approach safely",
        "Something came up",
        "Other..."
    ]
    
    var body: some View {
        VStack(spacing: AppConstants.spacingL) {
            // Modal Header
            VStack(spacing: 6) {
                Text("What happened?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.black)
                
                Text("This case will go back on the map so someone else can pick it up.")
                    .font(AppFonts.footnote())
                    .foregroundColor(AppColors.gray500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, AppConstants.spacingL)
            
            // Reason options
            VStack(spacing: 10) {
                ForEach(reasons, id: \.self) { reason in
                    Button {
                        selectedReason = reason
                    } label: {
                        HStack {
                            Spacer()
                            Text(reason)
                                .font(AppFonts.bodyMedium())
                                .foregroundColor(selectedReason == reason ? AppColors.primaryBlue : AppColors.black)
                            Spacer()
                        }
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge)
                                .fill(selectedReason == reason ? AppColors.primaryBlue.opacity(0.08) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge)
                                        .stroke(selectedReason == reason ? AppColors.primaryBlue : AppColors.gray200, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Optional Caption textfield
            TextField("Add a caption.....", text: $customCaption)
                .font(AppFonts.body())
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge)
                        .stroke(AppColors.gray200, lineWidth: 1)
                )
            
            // Submit Button
            Button {
                appState.unassignCase(reportId: reportId)
                isPresented = false
                onCaseUnassigned()
            } label: {
                Text("Submit")
                    .font(AppFonts.button())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.buttonHeight)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .padding(.horizontal, AppConstants.horizontalPadding)
        .padding(.bottom, AppConstants.spacingXL)
        .background(Color.white)
        .presentationDetents([.fraction(0.65)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(AppConstants.cornerRadiusXXL)
    }
}
