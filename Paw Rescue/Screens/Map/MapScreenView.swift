import SwiftUI
import MapKit
import CoreLocation

struct MapScreenView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var locManager = MapLocationDelegate()
    @State private var selectedReportId: UUID?
    @State private var selectedDetailReport: DogReport?
    @State private var selectedYourCaseReport: DogReport?
    @State private var showReportFlow = false
    @AppStorage("hasSeenFirstTimeHint") private var hasSeenFirstTimeHint = false
    @State private var showHint = true
    
    /// Map camera position centered on user / Kuta Bali
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: MockData.kutaCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    )
    
    private var activeReports: [DogReport] {
        appState.dogReports.filter { report in
            if report.isCompleted { return false }
            if let name = report.cloudKitRecordName, appState.completedCaseRecordNames.contains(name) { return false }
            if appState.completedCaseRecordNames.contains(report.id.uuidString) { return false }
            return true
        }
    }
    
    var body: some View {
        ZStack {
            // Map with dynamic reports, user location accuracy disk, and pins
            Map(position: $cameraPosition, selection: $selectedReportId) {
                // User's Real / Current Location Marker (Green radius halo + Blue dot matching Image 2)
                Annotation("", coordinate: appState.userCurrentCoordinate) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "4CAF50").opacity(0.28))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(Color(hex: "2196F3"))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Dog Case Annotations — real pins from CloudKit
                ForEach(activeReports) { report in
                    let isAccepted = (report.rescuerUserID != nil && !report.rescuerUserID!.isEmpty) || report.isAssignedToUser
                    Annotation(report.title, coordinate: report.coordinate) {
                        DogAnnotationView(
                            urgency: report.urgency,
                            isAccepted: isAccepted,
                            isSelected: selectedReportId == report.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                                selectedReportId = report.id
                            }
                            selectedDetailReport = report
                        }
                    }
                    .tag(report.id)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .including([.park, .hospital, .publicTransport, .restaurant])))
            .ignoresSafeArea()
            .onChange(of: selectedReportId) { _, newId in
                if let newId = newId, let found = appState.dogReports.first(where: { $0.id == newId }) {
                    selectedDetailReport = found
                }
            }
            
            // Subtle top indicator when syncing reports
            if appState.isLoadingReports && activeReports.isEmpty {
                VStack {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(AppColors.primaryBlue)
                            .scaleEffect(0.8)
                        Text("Syncing cases...")
                            .font(AppFonts.captionMedium())
                            .foregroundColor(AppColors.black)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.95), in: Capsule())
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.25), value: appState.isLoadingReports)
            }
            
            // Bottom-Right Floating Camera Action Button + Tooltip (Image 2)
            VStack {
                Spacer()
                
                HStack(alignment: .center, spacing: 14) {
                    Spacer()
                    
                    // "Tap here to report" Tooltip bubble with triangle pointer
                    if showHint {
                        HStack(spacing: 0) {
                            Text("Tap here to report")
                                .font(AppFonts.captionMedium())
                                .foregroundColor(AppColors.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                            
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(90))
                                .offset(x: -2)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    // Larger Blue Camera FAB
                    Button {
                        withAnimation {
                            showHint = false
                        }
                        showReportFlow = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryBlue)
                                .frame(width: 68, height: 68)
                                .shadow(color: AppColors.primaryBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, AppConstants.horizontalPadding)
                .padding(.bottom, 28)
            }
        }
        .sheet(item: $selectedDetailReport, onDismiss: {
            selectedReportId = nil
        }) { report in
            DogDetailSheet(
                report: report,
                isPresented: Binding(
                    get: { selectedDetailReport != nil },
                    set: { if !$0 { selectedDetailReport = nil } }
                )
            ) { selected in
                selectedDetailReport = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    selectedYourCaseReport = selected
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(AppConstants.cornerRadiusXXL)
            .environmentObject(appState)
        }
        .fullScreenCover(item: $selectedYourCaseReport) { report in
            YourCaseView(report: report)
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showReportFlow) {
            InstructionsView(isPresented: $showReportFlow)
                .environmentObject(appState)
        }
        .onAppear {
            // Get real GPS location
            locManager.requestLocation { userCoord in
                appState.userCurrentCoordinate = userCoord
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: userCoord,
                        span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                    )
                )
            }
            // Refresh pins from CloudKit
            appState.loadReports()
        }
    }
}

// MARK: - Location Delegate
final class MapLocationDelegate: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var onLocationReceived: ((CLLocationCoordinate2D) -> Void)?
    private var hasFiredInitialLocation = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocation(completion: @escaping (CLLocationCoordinate2D) -> Void) {
        self.onLocationReceived = completion
        self.hasFiredInitialLocation = false
        
        let status = manager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Already have permission — request immediately
            manager.requestLocation()
        case .notDetermined:
            // Show the popup — location will be requested in the delegate callback once granted
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Can't get location — stay on mock coordinate
            break
        @unknown default:
            manager.requestWhenInUseAuthorization()
        }
    }
    
    // Called IMMEDIATELY when the user taps Allow or Deny on the permission popup
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission just granted — now request the real location
            if !hasFiredInitialLocation {
                manager.requestLocation()
            }
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        hasFiredInitialLocation = true
        DispatchQueue.main.async {
            self.onLocationReceived?(loc.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Fallback to Kuta Center gracefully — no crash
        print("[Location] Failed to get location: \(error.localizedDescription)")
    }
}

#Preview {
    MapScreenView()
        .environmentObject(AppState())
}
