import SwiftUI
import MapKit
import CoreLocation

/// Interactive pin placement screen for placing the dog report accurately on the live map.
struct PlacePinMapView: View {
    @EnvironmentObject private var appState: AppState
    let report: DogReport
    @Binding var isReportFlowPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var locationAddress: String = "Park 23, Kuta"
    @State private var isGeocoding = false
    @State private var isPublishing = false
    @State private var cameraPosition: MapCameraPosition
    
    init(report: DogReport, isReportFlowPresented: Binding<Bool>) {
        self.report = report
        self._isReportFlowPresented = isReportFlowPresented
        let initialCoord = report.coordinate
        self._selectedCoordinate = State(initialValue: initialCoord)
        self._cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: initialCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            )
        ))
    }
    
    var body: some View {
        ZStack {
            // Interactive Map
            MapReader { reader in
                Map(position: $cameraPosition) {
                    // User's current location overlay
                    Annotation("Your Location", coordinate: appState.userCurrentCoordinate) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "4CAF50").opacity(0.25))
                                .frame(width: 50, height: 50)
                            Circle()
                                .fill(Color(hex: "2196F3"))
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .including([.park, .hospital, .publicTransport])))
                .ignoresSafeArea()
                .onMapCameraChange(frequency: .onEnd) { context in
                    selectedCoordinate = context.region.center
                    reverseGeocode(context.region.center)
                }
                .onTapGesture { screenPoint in
                    if let newCoord = reader.convert(screenPoint, from: .local) {
                        selectedCoordinate = newCoord
                        reverseGeocode(newCoord)
                    }
                }
            }
            
            // Center Pin Marker with Urgency Color & Paw Icon
            VStack(spacing: 0) {
                ZStack {
                    if report.urgency.isUrgentPulsing {
                        Circle()
                            .fill(report.urgency.color.opacity(0.3))
                            .frame(width: 54, height: 54)
                    }
                    
                    Circle()
                        .fill(report.urgency.color)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                        .shadow(color: report.urgency.color.opacity(0.5), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Pin pointer leg
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 14))
                    .foregroundColor(report.urgency.color)
                    .offset(y: -4)
                
                // Shadow underneath
                Ellipse()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 16, height: 6)
                    .offset(y: -2)
            }
            .allowsHitTesting(false)
            
            // Top Navigation & Instruction Header
            VStack(spacing: 12) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(LiquidGlassCircleButtonStyle(size: 38))
                    
                    Spacer()
                    
                    Text("Place Pin on Map")
                        .font(AppFonts.title3())
                        .foregroundColor(AppColors.black)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 38, height: 38)
                }
                .padding(.horizontal, AppConstants.horizontalPadding)
                .padding(.top, AppConstants.spacingM)
                
                // Location Address Banner
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(report.urgency.color)
                        .font(.system(size: 16, weight: .semibold))
                    
                    if isGeocoding {
                        ProgressView()
                            .tint(AppColors.primaryBlue)
                            .scaleEffect(0.8)
                    } else {
                        Text(locationAddress)
                            .font(AppFonts.bodySemibold())
                            .foregroundColor(AppColors.black)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text("Tap map to move")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.gray500)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXL))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                .padding(.horizontal, AppConstants.horizontalPadding)
                
                Spacer()
                
                // Bottom Confirmation Card
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reporting Dog")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.gray500)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(report.urgency.color)
                                    .frame(width: 8, height: 8)
                                Text("Priority: \(report.urgency.rawValue)")
                                    .font(AppFonts.bodySemibold())
                                    .foregroundColor(report.urgency.color)
                            }
                        }
                        
                        Spacer()
                        
                        Text(report.symptoms.map { $0.name }.joined(separator: " • "))
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.gray600)
                            .lineLimit(1)
                    }
                    
                    Button {
                        publishPinAndFinish()
                    } label: {
                        HStack(spacing: 8) {
                            if isPublishing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 18))
                                Text("Confirm Location & Publish")
                                    .font(AppFonts.button())
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppConstants.buttonHeight)
                        .background(AppColors.primaryBlue)
                        .clipShape(Capsule())
                        .shadow(color: AppColors.primaryBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPublishing)
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadiusXXL))
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                .padding(.horizontal, AppConstants.horizontalPadding)
                .padding(.bottom, AppConstants.spacingXL)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            reverseGeocode(selectedCoordinate)
        }
    }
    
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            isGeocoding = false
            if let place = placemarks?.first {
                let street = place.name ?? place.thoroughfare ?? "Park 23"
                let locality = place.locality ?? "Kuta"
                locationAddress = "\(street), \(locality)"
            } else {
                locationAddress = "Kuta Beach, Bali"
            }
        }
    }
    
    private func publishPinAndFinish() {
        isPublishing = true
        
        // Update the report in AppState with the finalized coordinate & location address
        appState.updateReport(
            reportId: report.id,
            newCoordinate: selectedCoordinate,
            newLocationName: locationAddress
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isPublishing = false
            // Dismiss the entire reporting flow so the user lands on the Map tab with their new live pin
            isReportFlowPresented = false
        }
    }
}
