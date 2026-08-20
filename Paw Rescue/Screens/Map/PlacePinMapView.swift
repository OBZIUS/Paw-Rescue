import SwiftUI
import MapKit
import CoreLocation

/// Interactive pin placement screen for placing the dog report accurately on the live map.
struct PlacePinMapView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isReportFlowPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var locationAddress: String = "Locating..."
    @State private var isGeocoding = false
    @State private var showLoading = false
    @State private var cameraPosition: MapCameraPosition
    
    init(isReportFlowPresented: Binding<Bool>) {
        self._isReportFlowPresented = isReportFlowPresented
        let initialCoord = MockData.kutaCenter
        self._selectedCoordinate = State(initialValue: initialCoord)
        self._cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: initialCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            )
        ))
    }
    
    private var urgency: UrgencyLevel {
        appState.currentFormData.calculatedUrgency
    }
    
    var body: some View {
        NavigationStack {
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
                
                // Center Pin Marker with Urgency Teardrop Shape
                VStack(spacing: 2) {
                    ZStack {
                        TeardropPinShape()
                            .fill(urgency.color)
                            .frame(width: 38, height: 46)
                            .overlay(
                                TeardropPinShape()
                                    .stroke(Color.white, lineWidth: 2.5)
                            )
                            .shadow(color: urgency.color.opacity(0.45), radius: 6, x: 0, y: 3)
                        
                        Image(systemName: "pawprint")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .offset(y: -4)
                    }
                    
                    // Anchor Base Dot below the tip
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                        .overlay(
                            Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
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
                            .foregroundColor(urgency.color)
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
                                        .fill(urgency.color)
                                        .frame(width: 8, height: 8)
                                    Text("Priority: \(urgency.rawValue)")
                                        .font(AppFonts.bodySemibold())
                                        .foregroundColor(urgency.color)
                                }
                            }
                            
                            Spacer()
                            
                            if let wound = appState.currentFormData.woundStatus, wound.contains("bleeding") {
                                Text("Bleeding")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.gray600)
                            }
                        }
                        
                        Button {
                            confirmLocationAndProceed()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("Confirm Location & Publish")
                                    .font(AppFonts.button())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppConstants.buttonHeight)
                            .background(AppColors.primaryBlue)
                            .clipShape(Capsule())
                            .shadow(color: AppColors.primaryBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
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
                selectedCoordinate = appState.userCurrentCoordinate
                cameraPosition = .region(MKCoordinateRegion(
                    center: appState.userCurrentCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                ))
                reverseGeocode(appState.userCurrentCoordinate)
            }
            .fullScreenCover(isPresented: $showLoading) {
                LoadingView(isReportFlowPresented: $isReportFlowPresented)
                    .environmentObject(appState)
            }
        }
    }
    
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            isGeocoding = false
            if let place = placemarks?.first {
                let street = place.name ?? place.thoroughfare ?? "Gang Mayura"
                let locality = place.locality ?? "Kuta"
                locationAddress = "\(street), \(locality)"
            } else {
                locationAddress = "Gang Mayura, Kuta"
            }
        }
    }
    
    private func confirmLocationAndProceed() {
        appState.currentFormData.selectedCoordinate = selectedCoordinate
        appState.currentFormData.locationName = locationAddress
        showLoading = true
    }
}
