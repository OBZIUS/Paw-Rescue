import SwiftUI
import MapKit

/// "Your Case" view for active rescues with photo carousel and rescue completion.
struct YourCaseView: View {
    @EnvironmentObject private var appState: AppState
    let report: DogReport
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCantHelpSheet = false
    @State private var showThankYouDialog = false
    @State private var showShareFeed = false
    @State private var selectedPhotoIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
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
                                
                                Text("Your Case")
                                    .font(AppFonts.title())
                                    .foregroundColor(AppColors.black)
                                
                                Spacer()
                                
                                Color.clear.frame(width: 36, height: 36)
                            }
                            .padding(.top, AppConstants.spacingM)
                            
                            // Dog photo (carousel if multiple)
                            if !report.photos.isEmpty {
                                TabView(selection: $selectedPhotoIndex) {
                                    ForEach(Array(report.photos.enumerated()), id: \.offset) { index, photo in
                                        Image(uiImage: photo)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 220)
                                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                                            .tag(index)
                                    }
                                }
                                .frame(height: 220)
                                .tabViewStyle(.page(indexDisplayMode: report.photos.count > 1 ? .always : .never))
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                                .padding(.top, 4)
                            } else if let customImage = report.customImage {
                                Image(uiImage: customImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                                    .padding(.top, 4)
                            } else {
                                RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL)
                                    .fill(AppColors.secondaryCream)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .overlay(
                                        Image(systemName: "pawprint.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(AppColors.primaryBlue.opacity(0.4))
                                    )
                                    .padding(.top, 4)
                            }
                            
                            // Description Card
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(AppFonts.bodySemibold())
                                    .foregroundColor(AppColors.black)
                                
                                Text(report.description)
                                    .font(AppFonts.bodyMedium())
                                    .foregroundColor(AppColors.gray600)
                                    .lineSpacing(3)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                            
                            // Location Row with "Get Direction"
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(report.urgency.color)
                                    
                                    Text(report.location)
                                        .font(AppFonts.bodySemibold())
                                        .foregroundColor(AppColors.black)
                                }
                                
                                Spacer()
                                
                                Button {
                                    openAppleMaps(coordinate: report.coordinate, name: report.location)
                                } label: {
                                    Text("Get Direction")
                                        .font(AppFonts.bodySemibold())
                                        .foregroundColor(AppColors.primaryBlue)
                                        .underline()
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 8)
                            
                            // Symptoms
                            VStack(alignment: .leading, spacing: AppConstants.spacingM) {
                                Text("Symptoms")
                                    .font(AppFonts.bodySemibold())
                                    .foregroundColor(AppColors.black)
                                
                                ForEach(report.symptoms) { symptom in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(report.urgency.color.opacity(0.15))
                                                .frame(width: 38, height: 38)
                                            
                                            Image(systemName: symptom.iconName)
                                                .font(.system(size: 17, weight: .medium))
                                                .foregroundColor(report.urgency.color)
                                        }
                                        
                                        Text(symptom.name)
                                            .font(AppFonts.bodyMedium())
                                            .foregroundColor(AppColors.black)
                                    }
                                }
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                            .padding(.bottom, 16)
                        }
                        .padding(.horizontal, AppConstants.horizontalPadding)
                    }
                    
                    // Pinned Bottom Action Buttons: "Can't help" and "Mark as done"
                    HStack(spacing: AppConstants.spacingM) {
                        // Can't Help Button
                        Button {
                            showCantHelpSheet = true
                        } label: {
                            Text("Can’t help")
                                .font(AppFonts.button())
                                .foregroundColor(AppColors.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppConstants.buttonHeight)
                                .background(AppColors.secondaryCream)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        // Mark as Done Button
                        Button {
                            showThankYouDialog = true
                        } label: {
                            Text("Mark as done")
                                .font(AppFonts.button())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppConstants.buttonHeight)
                                .background(AppColors.primaryBlue)
                                .clipShape(Capsule())
                                .shadow(color: AppColors.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, AppConstants.spacingHuge)
                    .background(AppColors.primaryBackground)
                }
                
                // "Thank you!" Popup Dialog (Image 2 middle)
                if showThankYouDialog {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showThankYouDialog = false
                        }
                    
                    VStack(spacing: AppConstants.spacingXL) {
                        // Stars & Checkmark
                        ZStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 16))
                                .offset(x: -45, y: -25)
                            
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 14))
                                .offset(x: 45, y: -25)
                            
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 18))
                                .offset(x: -30, y: 15)
                            
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                                .offset(x: 35, y: 20)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(AppColors.safe)
                        }
                        .frame(height: 70)
                        .padding(.top, 10)
                        
                        Text("Thank you!")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppColors.black)
                        
                        VStack(spacing: 12) {
                            // Share to feed button
                            Button {
                                showThankYouDialog = false
                                appState.markCaseDone(reportId: report.id)
                                showShareFeed = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Share to feed")
                                        .font(AppFonts.button())
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(AppColors.primaryBlue)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            
                            // Continue button
                            Button {
                                showThankYouDialog = false
                                appState.markCaseDone(reportId: report.id)
                                dismiss()
                            } label: {
                                Text("Continue")
                                    .font(AppFonts.button())
                                    .foregroundColor(AppColors.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(AppColors.gray200)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(28)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                    .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
                    .padding(.horizontal, 36)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCantHelpSheet) {
                CantHelpSheet(reportId: report.id, isPresented: $showCantHelpSheet) {
                    dismiss()
                }
            }
            .fullScreenCover(isPresented: $showShareFeed) {
                ShareFeedView(
                    report: report,
                    isPresented: $showShareFeed,
                    onPostShared: {
                        dismiss()
                    }
                )
                .environmentObject(appState)
            }
        }
    }
    
    private func openAppleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
