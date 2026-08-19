import SwiftUI

/// Bottom sheet showing dog report details with liquid glass controls and "Help this dog" navigation.
struct DogDetailSheet: View {
    @EnvironmentObject private var appState: AppState
    let report: DogReport
    @Binding var isPresented: Bool
    var onHelpTapped: (DogReport) -> Void
    
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
                    
                    // Reporter info row
                    HStack {
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
                                Text("Reported by \(report.reporterName)")
                                    .font(AppFonts.bodySemibold())
                                    .foregroundColor(AppColors.black)
                                
                                Text(report.timeReported)
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.gray500)
                            }
                        }
                        
                        Spacer()
                        
                        // Urgency Badge (e.g. Red dot Emergency)
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
                    
                    // Help this dog button
                    Button {
                        appState.assignCaseToUser(reportId: report.id)
                        isPresented = false
                        onHelpTapped(report)
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
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(LiquidGlassCircleButtonStyle(size: 32))
                }
            }
        }
    }
}
