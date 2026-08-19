import SwiftUI
import MapKit

/// Case overview and editing screen matching reference design.
struct EditCaseView: View {
    @EnvironmentObject private var appState: AppState
    let report: DogReport
    @Binding var isReportFlowPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditingDescription: Bool = false
    @State private var editedDescription: String = ""
    @State private var selectedPhotoIndex: Int = 0
    @State private var showPlacePin: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppConstants.spacingL) {
                        // Header with Liquid Glass Back Button & Title
                        HStack {
                            Button {
                                isReportFlowPresented = false
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .buttonStyle(LiquidGlassCircleButtonStyle(size: 36))
                            
                            Spacer()
                            
                            Text("Edit Case")
                                .font(AppFonts.title())
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 36, height: 36)
                        }
                        .padding(.top, AppConstants.spacingM)
                        
                        // All clicked photos (Carousel / Horizontal Paging, NO edit pencil)
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
                        
                        // Description Card with interactive inline editing
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Description")
                                    .font(AppFonts.bodySemibold())
                                    .foregroundColor(AppColors.primaryBlue)
                                
                                Spacer()
                                
                                Button {
                                    if isEditingDescription {
                                        appState.updateReportDescription(reportId: report.id, newDescription: editedDescription)
                                    } else {
                                        editedDescription = report.description
                                    }
                                    withAnimation {
                                        isEditingDescription.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        if isEditingDescription {
                                            Text("Done")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(AppColors.primaryBlue)
                                        }
                                        Image(systemName: isEditingDescription ? "checkmark.circle.fill" : "pencil")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppColors.primaryBlue)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if isEditingDescription {
                                TextEditor(text: $editedDescription)
                                    .font(AppFonts.bodyMedium())
                                    .foregroundColor(AppColors.black)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .frame(minHeight: 90)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AppColors.primaryBlue.opacity(0.5), lineWidth: 1)
                                    )
                            } else {
                                Text(report.description)
                                    .font(AppFonts.bodyMedium())
                                    .foregroundColor(AppColors.black)
                                    .lineSpacing(3)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        
                        // Location Row
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
                                Text("Direction")
                                    .font(AppFonts.bodyMedium())
                                    .foregroundColor(AppColors.primaryBlue)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                        
                        // Symptoms (NO pencil button)
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
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // Mark as done / Place Pin on Map
                        Button {
                            if isEditingDescription {
                                appState.updateReportDescription(reportId: report.id, newDescription: editedDescription)
                            }
                            showPlacePin = true
                        } label: {
                            Text("Mark as done")
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
            .fullScreenCover(isPresented: $showPlacePin) {
                PlacePinMapView(report: report, isReportFlowPresented: $isReportFlowPresented)
                    .environmentObject(appState)
            }
            .onAppear {
                editedDescription = report.description
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
