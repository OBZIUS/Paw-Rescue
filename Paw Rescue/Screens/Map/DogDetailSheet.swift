import SwiftUI

/// Bottom sheet showing dog report details with liquid glass controls and "Help this dog" navigation.
struct DogDetailSheet: View {
    @EnvironmentObject private var appState: AppState
    let report: DogReport
    @Binding var isPresented: Bool
    var onHelpTapped: (DogReport) -> Void
    
    @State private var selectedUserProfile: PublicUserProfile?
    
    private var currentUserID: String { AuthManager.shared.currentUserID }
    
    /// Always reads the freshest version of the report from the live store.
    private var liveReport: DogReport {
        appState.dogReports.first(where: { $0.cloudKitRecordName == report.cloudKitRecordName && report.cloudKitRecordName != nil })
        ?? appState.dogReports.first(where: { $0.id == report.id })
        ?? report
    }
    
    /// True if the current user is the one who reported this dog
    private var isCurrentUserReporter: Bool {
        !currentUserID.isEmpty && liveReport.reporterUserID == currentUserID
    }
    
    /// True if the current user is the one who accepted this rescue
    private var isCurrentUserRescuer: Bool {
        !currentUserID.isEmpty && liveReport.rescuerUserID == currentUserID
    }
    
    /// True if someone (not the current user) has already accepted the case
    private var isTakenByOther: Bool {
        guard let rescuerID = liveReport.rescuerUserID, !rescuerID.isEmpty else { return false }
        return rescuerID != currentUserID
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Dog image / Carousel
                    ZStack(alignment: .topTrailing) {
                        if !report.photos.isEmpty {
                            TabView {
                                ForEach(Array(report.photos.enumerated()), id: \.offset) { index, photo in
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipped()
                                }
                            }
                            .frame(height: 200)
                            .tabViewStyle(.page(indexDisplayMode: report.photos.count > 1 ? .always : .never))
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                        } else if let firstPhoto = report.customImage {
                            Image(uiImage: firstPhoto)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                        } else {
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL)
                                .fill(AppColors.secondaryCream)
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(AppColors.primaryBlue.opacity(0.4))
                                )
                        }
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.top, 12)
                    
                    // Reporter info row (Tappable to view public profile)
                    HStack {
                        Button {
                            selectedUserProfile = PublicUserProfile(
                                userID: report.reporterUserID,
                                username: report.reporterName
                            )
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.secondaryCream)
                                        .frame(width: 38, height: 38)
                                    Image(systemName: report.reporterAvatarName)
                                        .font(.system(size: 24))
                                        .foregroundColor(AppColors.primaryBlue)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text("Reported by \(report.reporterName)")
                                            .font(AppFonts.bodySemibold())
                                            .foregroundColor(AppColors.black)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AppColors.gray400)
                                    }
                                    
                                    Text(report.timeReported)
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.gray500)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Urgency Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(report.urgency.color)
                                .frame(width: 8, height: 8)
                            Text(report.urgency.rawValue)
                                .font(AppFonts.captionMedium())
                                .foregroundColor(report.urgency.color)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(report.urgency.color.opacity(0.12), in: Capsule())
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    
                    // MARK: - Rescuer Status Banner (Uniform styling matching YourCaseView)
                    // Shows when someone has accepted the case
                    if let rescuerName = report.rescuerName, !rescuerName.isEmpty {
                        Button {
                            selectedUserProfile = PublicUserProfile(
                                userID: report.rescuerUserID,
                                username: rescuerName
                            )
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.primaryBlue.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.primaryBlue)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    if isCurrentUserRescuer {
                                        Text("You are rescuing this dog")
                                            .font(AppFonts.bodySemibold())
                                            .foregroundColor(AppColors.primaryBlue)
                                    } else {
                                        HStack(spacing: 4) {
                                            Text("\(rescuerName) is on their way")
                                                .font(AppFonts.bodySemibold())
                                                .foregroundColor(AppColors.primaryBlue)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(AppColors.primaryBlue.opacity(0.6))
                                        }
                                    }
                                    Text("Reported by \(report.reporterName)")
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.gray500)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColors.primaryBlue.opacity(0.5))
                            }
                            .padding(14)
                            .background(AppColors.primaryBlue.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                            .padding(.horizontal, AppConstants.horizontalPadding)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Location row
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(report.urgency.color)
                            
                            Text(report.location)
                                .font(AppFonts.bodySemibold())
                                .foregroundColor(AppColors.black)
                        }
                        
                        Spacer()
                        
                        Text(report.distance)
                            .font(AppFonts.footnote())
                            .foregroundColor(AppColors.gray500)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    
                    Divider()
                        .padding(.horizontal, AppConstants.horizontalPadding)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(AppFonts.bodySemibold())
                            .foregroundColor(AppColors.black)
                        
                        Text(report.description)
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.gray600)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    
                    // Symptoms
                    if !report.symptoms.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Symptoms")
                                .font(AppFonts.bodySemibold())
                                .foregroundColor(AppColors.black)
                            
                            ForEach(report.symptoms) { symptom in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(report.urgency.color.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: symptom.iconName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(report.urgency.color)
                                    }
                                    
                                    Text(symptom.name)
                                        .font(AppFonts.bodyMedium())
                                        .foregroundColor(AppColors.black)
                                }
                            }
                        }
                        .padding(.horizontal, AppConstants.horizontalPadding)
                    }
                    
                    Spacer()
                        .frame(height: 12)
                    
                    // MARK: - Bottom Button
                    // Shows different states based on who the user is
                    Group {
                        if isCurrentUserRescuer {
                            // Already the rescuer — go to Your Case
                            Button {
                                isPresented = false
                                onHelpTapped(report)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("View Your Case")
                                        .font(AppFonts.button())
                                }
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppConstants.buttonHeight)
                                .background(AppColors.primaryBlue)
                                .clipShape(Capsule())
                                .shadow(color: AppColors.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                            
                        } else if isCurrentUserReporter {
                            // You reported this — view your report in activity
                            Button {
                                isPresented = false
                                onHelpTapped(report)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "eye.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("View Your Report")
                                        .font(AppFonts.button())
                                }
                                .foregroundColor(AppColors.primaryBlue)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppConstants.buttonHeight)
                                .background(AppColors.primaryBlue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            
                        } else if isTakenByOther {
                            // Someone else accepted — show Got it dismiss button
                            Button {
                                isPresented = false
                            } label: {
                                Text("Got it")
                                    .font(AppFonts.button())
                                    .foregroundColor(AppColors.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: AppConstants.buttonHeight)
                                    .background(AppColors.secondaryCream)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            
                        } else if liveReport.isCompleted {
                            // Already completed
                            Button {
                                isPresented = false
                            } label: {
                                Text("This dog is already rescued")
                                    .font(AppFonts.button())
                                    .foregroundColor(AppColors.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: AppConstants.buttonHeight)
                                    .background(AppColors.secondaryCream)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Normal — first to accept
                            Button {
                                appState.assignCaseToUser(reportId: liveReport.id, recordName: liveReport.cloudKitRecordName ?? report.cloudKitRecordName)
                                isPresented = false
                                onHelpTapped(liveReport)
                            } label: {
                                Text("Help this dog")
                                    .font(AppFonts.button())
                                    .foregroundColor(AppColors.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: AppConstants.buttonHeight)
                                    .background(AppColors.primaryBlue)
                                    .clipShape(Capsule())
                                    .shadow(color: AppColors.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.bottom, AppConstants.spacingXL)
                }
            }
            .background(AppColors.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(report.urgency.rawValue)
                        .font(AppFonts.title3())
                        .foregroundColor(AppColors.black)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.black.opacity(0.75))
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 0.8))
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(item: $selectedUserProfile) { profile in
                PublicProfileSheet(profile: profile)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppConstants.cornerRadiusXXL)
                    .environmentObject(appState)
            }
        }
    }
}
