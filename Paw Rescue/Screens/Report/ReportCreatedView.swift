import SwiftUI
import MapKit

/// Post-submission screen: "Report Created" with Priority Triage, Safety Notice, and Nearest Shelters.
struct ReportCreatedView: View {
    @EnvironmentObject private var appState: AppState
    let report: DogReport
    @Binding var isReportFlowPresented: Bool
    @State private var showEditCase = false
    
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
                                isReportFlowPresented = false
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .buttonStyle(LiquidGlassCircleButtonStyle(size: 36))
                            
                            Spacer()
                        }
                        .padding(.top, AppConstants.spacingM)
                        
                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Important")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(AppColors.black)
                            
                            Text("Your report is live on the rescue network.")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.gray500)
                        }
                        .padding(.top, 4)
                        
                        // Priority Card (Triage algorithm result)
                        VStack(spacing: 8) {
                            Text("Priority")
                                .font(AppFonts.captionMedium())
                                .foregroundColor(AppColors.gray500)
                            
                            Text(report.urgency.rawValue)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(report.urgency.color)
                            
                            Text(report.urgency.description)
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.gray600)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(.vertical, 22)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                        
                        // Safety Notice Card
                        HStack(alignment: .top, spacing: 12) {
                            Text("Do not touch or approach. An injured dog bites, and rabies is present in Bali. Stay back and let trained responders handle contact.")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.black.opacity(0.85))
                                .lineSpacing(3)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        
                        // Nearest Animal Shelter Section
                        Text("Nearest Animal Shelter")
                            .font(AppFonts.bodySemibold())
                            .foregroundColor(AppColors.black)
                            .padding(.top, 6)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppConstants.spacingM) {
                                ForEach(MockData.nearestShelters) { shelter in
                                    shelterCard(shelter)
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // Continue Button -> Edit Case
                        Button {
                            showEditCase = true
                        } label: {
                            Text("Continue")
                                .font(AppFonts.button())
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppConstants.buttonHeight)
                                .background(AppColors.primaryBlue)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, AppConstants.spacingHuge)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showEditCase) {
                EditCaseView(report: report, isReportFlowPresented: $isReportFlowPresented)
                    .environmentObject(appState)
            }
        }
    }
    
    @ViewBuilder
    private func shelterCard(_ shelter: AnimalShelter) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(shelter.name)
                    .font(AppFonts.bodySemibold())
                    .foregroundColor(AppColors.black)
                
                Spacer()
                
                Text(shelter.status)
                    .font(AppFonts.captionMedium())
                    .foregroundColor(AppColors.safe)
            }
            
            Text(shelter.distanceTime)
                .font(AppFonts.caption())
                .foregroundColor(AppColors.gray500)
            
            HStack(spacing: 8) {
                // Call Button
                Button {
                    if let url = URL(string: "tel://\(shelter.phoneNumber)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Call")
                        .font(AppFonts.buttonSmall())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(AppColors.primaryBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                // Direction Button
                Button {
                    openAppleMaps(coordinate: shelter.coordinate, name: shelter.name)
                } label: {
                    Text("Direction")
                        .font(AppFonts.buttonSmall())
                        .foregroundColor(AppColors.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppColors.primaryBlue, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(width: 240)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
    
    private func openAppleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
