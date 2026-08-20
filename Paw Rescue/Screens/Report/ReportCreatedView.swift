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
                        
                        // Title (Centered matching reference)
                        VStack(spacing: 6) {
                            Text("Thank you\nfor your report!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppColors.black)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
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
                        
                        // Caution / Rabies Notice Card (Yellow tinted banner with bold red rabies)
                        VStack(alignment: .leading, spacing: 6) {
                            rabiesAttributedText()
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.black.opacity(0.85))
                                .lineSpacing(3)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "FFF8E1"))
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL)
                                .stroke(Color(hex: "FFE082"), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                        
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
                        
                        // Understood Button -> Dismisses entire report flow back to map
                        Button {
                            isReportFlowPresented = false
                        } label: {
                            Text("Understood")
                                .font(AppFonts.button())
                                .foregroundColor(AppColors.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppConstants.buttonHeight)
                                .background(AppColors.primaryBlue)
                                .clipShape(Capsule())
                                .shadow(color: AppColors.primaryBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, AppConstants.spacingHuge)
                    }
                    .padding(.horizontal, AppConstants.horizontalPadding)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func rabiesAttributedText() -> Text {
        Text("Do not touch or approach. ")
            .fontWeight(.bold)
        + Text("An injured dog bites, and ")
        + Text("rabies")
            .foregroundColor(.red)
            .fontWeight(.bold)
        + Text(" is present in Bali. Stay back and let trained responders handle contact.")
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
