import SwiftUI
import MapKit
import CoreLocation

/// Step 4: Confirmation Screen / Edit Report before final publishing.
struct EditCaseView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isReportFlowPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditingDescription: Bool = false
    @State private var editedDescription: String = ""
    @State private var selectedPhotoIndex: Int = 0
    @State private var showThankYou: Bool = false
    @State private var submittedReport: DogReport?
    
    private var formData: ReportFormData {
        appState.currentFormData
    }
    
    private var locationName: String {
        formData.locationName ?? "Gang Mayura, Kuta"
    }
    
    private var symptoms: [Symptom] {
        var list: [Symptom] = []
        if let wound = formData.woundStatus, wound.contains("bleeding") && !wound.contains("no wound") {
            list.append(Symptom(name: "Bleeding", iconName: "drop.fill"))
        }
        if let mobility = formData.mobilityStatus, mobility.contains("Struggles") || mobility.contains("Can't move") {
            list.append(Symptom(name: "Limping", iconName: "figure.walk"))
        }
        for cue in formData.visualCues {
            if cue.contains("Ribs") {
                list.append(Symptom(name: "Malnourished", iconName: "exclamationmark.triangle.fill"))
            } else if cue.contains("Bald") || cue.contains("Crusty") {
                list.append(Symptom(name: "Skin Issue", iconName: "allergens"))
            }
        }
        if list.isEmpty {
            list.append(Symptom(name: "Needs Care", iconName: "heart.fill"))
        }
        return list
    }
    
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
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                            .buttonStyle(LiquidGlassCircleButtonStyle(size: 36))
                            
                            Spacer()
                            
                            Text("Edit Report")
                                .font(AppFonts.title())
                                .foregroundColor(AppColors.black)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 36, height: 36)
                        }
                        .padding(.top, AppConstants.spacingM)
                        
                        // Dog photo with edit pencil
                        ZStack(alignment: .topTrailing) {
                            if !formData.photos.isEmpty {
                                TabView(selection: $selectedPhotoIndex) {
                                    ForEach(Array(formData.photos.enumerated()), id: \.offset) { index, photo in
                                        Image(uiImage: photo)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 220)
                                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                                            .tag(index)
                                    }
                                }
                                .frame(height: 220)
                                .tabViewStyle(.page(indexDisplayMode: formData.photos.count > 1 ? .always : .never))
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
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
                            }
                            
                            // Edit Pencil Icon on top-right
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.black.opacity(0.6), in: Circle())
                            }
                            .padding(12)
                        }
                        .padding(.top, 4)
                        
                        // Description Card with interactive inline editing
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Description")
                                    .font(AppFonts.bodySemibold())
                                    .foregroundColor(AppColors.primaryBlue)
                                
                                Spacer()
                                
                                Button {
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
                                if editedDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Add description (tap pencil to edit)...")
                                        .font(AppFonts.bodyMedium())
                                        .foregroundColor(AppColors.gray400)
                                        .italic()
                                } else {
                                    Text(editedDescription)
                                        .font(AppFonts.bodyMedium())
                                        .foregroundColor(AppColors.black)
                                        .lineSpacing(3)
                                }
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
                                    .foregroundColor(formData.calculatedUrgency.color)
                                
                                Text(locationName)
                                    .font(AppFonts.bodySemibold())
                                    .foregroundColor(AppColors.black)
                            }
                            
                            Spacer()
                            
                            Button {
                                if let coord = formData.selectedCoordinate {
                                    openAppleMaps(coordinate: coord, name: locationName)
                                }
                            } label: {
                                Text("Direction")
                                    .font(AppFonts.bodyMedium())
                                    .foregroundColor(AppColors.primaryBlue)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                        
                        // Symptoms Card
                        VStack(alignment: .leading, spacing: AppConstants.spacingM) {
                            Text("Symptoms")
                                .font(AppFonts.bodySemibold())
                                .foregroundColor(AppColors.black)
                            
                            ForEach(symptoms) { symptom in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(formData.calculatedUrgency.color.opacity(0.15))
                                            .frame(width: 38, height: 38)
                                        
                                        Image(systemName: symptom.iconName)
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(formData.calculatedUrgency.color)
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
                        
                        // Post Report Button
                        Button {
                            publishReport()
                        } label: {
                            Text("Post Report")
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
            .fullScreenCover(isPresented: $showThankYou) {
                if let report = submittedReport ?? appState.lastSubmittedReport {
                    ReportCreatedView(report: report, isReportFlowPresented: $isReportFlowPresented)
                        .environmentObject(appState)
                }
            }
            .onAppear {
                // Description starts empty or with what user typed in form
                editedDescription = formData.additionalDescription
            }
        }
    }
    
    private func publishReport() {
        var finalFormData = appState.currentFormData
        finalFormData.additionalDescription = editedDescription
        
        let report = appState.submitReport(
            formData: finalFormData,
            customCoordinate: finalFormData.selectedCoordinate,
            locationName: locationName
        )
        submittedReport = report
        showThankYou = true
    }
    
    private func openAppleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
