import SwiftUI

/// 2-Column grid view of all reported & rescued dogs matching reference design.
struct RescuedDogsGridView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReport: DogReport?
    @State private var showCaseDetail = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    private var myRescuedAndReportedDogs: [DogReport] {
        let currentUID = AuthManager.shared.currentUserID
        return appState.dogReports.filter { report in
            if let reporterID = report.reporterUserID, !reporterID.isEmpty, reporterID == currentUID {
                return true
            }
            if let rescuerID = report.rescuerUserID, !rescuerID.isEmpty, rescuerID == currentUID {
                return true
            }
            return appState.assignedCaseIDs.contains(report.id.uuidString)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppConstants.spacingL) {
                        // Header with Liquid Glass Back Button
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .buttonStyle(LiquidGlassCircleButtonStyle(size: 36))
                            
                            Spacer()
                            
                            Text("Reported & Rescued Dogs")
                                .font(AppFonts.title3())
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 36, height: 36)
                        }
                        .padding(.top, AppConstants.spacingM)
                        
                        // Empty state if user hasn't rescued or reported yet
                        if myRescuedAndReportedDogs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "pawprint.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppColors.gray300)
                                Text("No dogs reported or rescued yet")
                                    .font(AppFonts.bodyMedium())
                                    .foregroundColor(AppColors.gray500)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            // 2-Column Polaroid Grid
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(myRescuedAndReportedDogs) { report in
                                    polaroidCard(report)
                                        .onTapGesture {
                                            if report.isCompleted {
                                                // Dog already helped and posted to feed — take user to the Feed tab!
                                                appState.selectedTab = .home
                                                dismiss()
                                            } else {
                                                selectedReport = report
                                            }
                                        }
                                }
                            }
                            .padding(.top, 6)
                            .padding(.bottom, AppConstants.spacingHuge)
                        }
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedReport) { report in
                YourCaseView(report: report)
                    .environmentObject(appState)
            }
        }
    }
    
    @ViewBuilder
    private func polaroidCard(_ report: DogReport) -> some View {
        let currentUID = AuthManager.shared.currentUserID
        
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let customImage = report.photos.first ?? report.customImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 125)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.secondaryCream)
                        .frame(height: 125)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 36))
                                .foregroundColor(AppColors.primaryBlue.opacity(0.35))
                        )
                }
                
                // MARK: - Dynamic Helper & Status Badge
                Group {
                    if report.isCompleted {
                        // 1. Dog was helped & case closed
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("Dog Helped")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(AppColors.safe, in: Capsule())
                    } else if let rescuerName = report.rescuerName, !rescuerName.isEmpty {
                        // 2. Dog is being helped by someone
                        let isMe = report.rescuerUserID == currentUID
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 9, weight: .bold))
                            Text(isMe ? "Rescued by You" : "Helped by \(rescuerName)")
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(AppColors.primaryBlue, in: Capsule())
                    } else {
                        // 3. Dog is NOT helped yet
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 5, height: 5)
                            Text("Needs Help")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color(hex: "E53935"), in: Capsule())
                    }
                }
                .padding(6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(report.title)
                    .font(AppFonts.bodyBold())
                    .foregroundColor(AppColors.black)
                    .lineLimit(1)
                
                HStack {
                    Text(report.location)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.gray500)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(report.dateFormatted)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(AppColors.gray400)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    RescuedDogsGridView()
        .environmentObject(AppState())
}
