import SwiftUI

/// "What happened?" modal sheet styled cleanly in light mode matching the app's design system.
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
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Text("What happened?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.black)
                
                Text("This case will go back on the map so someone else can pick it up.")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.gray600)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 22)
            .padding(.bottom, 18)
            
            // Options List
            VStack(spacing: 8) {
                ForEach(reasons, id: \.self) { reason in
                    Button {
                        selectedReason = reason
                    } label: {
                        HStack {
                            Text(reason)
                                .font(AppFonts.bodyMedium())
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            if selectedReason == reason {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppColors.primaryBlue)
                            } else {
                                Circle()
                                    .stroke(AppColors.gray300, lineWidth: 1.5)
                                    .frame(width: 18, height: 18)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(
                            selectedReason == reason
                            ? AppColors.primaryBlue.opacity(0.08)
                            : Color.white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge)
                                .stroke(
                                    selectedReason == reason ? AppColors.primaryBlue : AppColors.gray200,
                                    lineWidth: selectedReason == reason ? 1.5 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppConstants.horizontalPadding)
            
            // Additional info textfield with clearly visible dark placeholder
            ZStack(alignment: .leading) {
                if customCaption.isEmpty {
                    Text("Additional info (optional)")
                        .font(AppFonts.bodyMedium())
                        .foregroundColor(AppColors.gray600)
                        .padding(.horizontal, 16)
                }
                TextField("", text: $customCaption)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.black)
                    .padding(.horizontal, 16)
            }
            .frame(height: 48)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadiusLarge)
                    .stroke(AppColors.gray300, lineWidth: 1)
            )
            .padding(.horizontal, AppConstants.horizontalPadding)
            .padding(.top, 10)
            
            Spacer(minLength: 16)
            
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
                    .shadow(color: AppColors.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppConstants.horizontalPadding)
            .padding(.bottom, 24)
        }
        .background(AppColors.primaryBackground)
        .preferredColorScheme(.light)
        .presentationDetents([.height(460)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(AppConstants.cornerRadiusXXL)
    }
}
