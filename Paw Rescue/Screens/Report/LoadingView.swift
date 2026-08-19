import SwiftUI

/// Loading screen with fixed-position paw prints fading and glowing sequentially from bottom to top.
struct LoadingView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isReportFlowPresented: Bool
    @State private var activePawIndex: Int = 0
    @State private var showReportCreated = false
    
    // Fixed paw print positions (bottom to top sequence)
    private let paws: [(x: CGFloat, y: CGFloat, rotation: Double)] = [
        (x: 0.55, y: 0.68, rotation: 15),
        (x: 0.42, y: 0.58, rotation: -12),
        (x: 0.56, y: 0.48, rotation: 18),
        (x: 0.40, y: 0.38, rotation: -10),
        (x: 0.54, y: 0.28, rotation: 12),
        (x: 0.44, y: 0.18, rotation: -15)
    ]
    
    var body: some View {
        ZStack {
            AppColors.primaryBackground
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                ForEach(Array(paws.enumerated()), id: \.offset) { index, paw in
                    let isVisible = index <= activePawIndex
                    
                    ZStack {
                        // Subtle glowing aura
                        Circle()
                            .fill(AppColors.primaryBlue.opacity(isVisible ? 0.15 : 0))
                            .frame(width: 60, height: 60)
                            .scaleEffect(isVisible ? 1.1 : 0.8)
                        
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 42, weight: .medium))
                            .foregroundColor(AppColors.primaryBlue)
                            .rotationEffect(.degrees(paw.rotation))
                    }
                    .position(
                        x: geometry.size.width * paw.x,
                        y: geometry.size.height * paw.y
                    )
                    .opacity(isVisible ? 1.0 : 0.08)
                    .animation(.easeIn(duration: 0.4), value: activePawIndex)
                }
            }
            
            // Bottom text
            VStack {
                Spacer()
                
                Text("We're filing your report...")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.black)
                    .padding(.bottom, 80)
            }
        }
        .onAppear {
            // Animate fade-in step-by-step from bottom to top without moving positions
            for i in 0..<paws.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.35) {
                    activePawIndex = i
                }
            }
            
            // Save report into live app data
            let createdReport = appState.submitReport(formData: appState.currentFormData)
            
            // Navigate to "Report Created" screen after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                showReportCreated = true
            }
        }
        .fullScreenCover(isPresented: $showReportCreated) {
            if let report = appState.lastSubmittedReport {
                ReportCreatedView(report: report, isReportFlowPresented: $isReportFlowPresented)
                    .environmentObject(appState)
            }
        }
    }
}

#Preview {
    LoadingView(isReportFlowPresented: .constant(true))
        .environmentObject(AppState())
}
